from typing import Union
from django.db import connections
from aioa.settings import v, s
from aioa.sql import *
from aioa.utils import logger, to_int, is_num, zip_data, get_fn_by_path
from apps.base.config import SystemConfig
from apps.base.views import get_roles
from .parser import ConfParser
from .verify import is_valid
import json


class BaseTableUtils:

    def __init__(self, request):
        # Query(GET)
        self.k_init = '_init'
        self.k_gid = 'gid'
        self.k_size = 'size'
        self.k_currentpage = 'currentpage'
        self.k_orders = 'orders'
        self.k_fulltext = 'fulltext'

        # Autocomplete
        self.k_autocomplete = '_autocomplete'
        self.k_val = '_val'
        self.k_type = '_type'

        # File download(GET)
        self.k_f_pk = '_f_pk'
        self.k_f_key = '_f_key'
        self.k_f_info = '_f_info'
        self.k_f_rel = '_f_rel'

        # Raw row data for edit(GET)
        self.k_pk = '_pk'
        self.k_type = '_type'
        self.k_status = '_status'

        # Tools(GET|POST)
        self.k_tool = '_tool'

        # Relations(GET)
        self.k_relation = '_relation'
        self.k_relation_pk = '_relation_pk'

        # Edit(POST)
        self.k_is_super = '_is_super'
        self.k_pk = '_pk'
        self.k_status = '_status'
        self.k_form_data = '_form_data'

        # Verify(POST)
        self.k_pks = '_pks'
        self.k_status = '_status'
        self.k_command = '_command'
        self.k_form_data = '_form_data'

        # Other
        self.default_rid = 0
        self.default_gid = 0
        self.default_status = '0'

        self.result = {}
        self.context = {'status': s.ok}
        self.is_authenticated = True

        self.request = request
        self.username = request.user.username

        self.path = request.path_info[len(v.url_prefix):]
        gid = to_int(request.GET.get(self.k_gid), self.default_gid)

        self.sc = SystemConfig(self.username)
        self.mid, self.gid, self.conf, self.modules = self.sc.get_module(self.path, gid)

        logger.debug('mid: {}, gid: {}, conf: \r\n{}'.format(self.mid, self.gid, self.conf))

        if self.conf:
            self.is_super = request.POST.get(self.k_is_super, 'false') == 'true'
            self.pk = request.POST.get(self.k_pk)  # '0' | None | '...'
            self.pks = request.POST.getlist(self.k_pks)  # [] | [...]
            self.form_data = json.loads(request.POST.get(self.k_form_data, '{}'))

            self.uid = request.user.id
            self.fullname = request.user.first_name if self.uid else ''

            self.roles = get_roles(self.username)
            self.rid = to_int(request.COOKIES.get('rid'), self.default_rid)
            self.rolename = None

            if self.rid:
                for role in self.roles:
                    if role['id'] == self.rid:
                        self.rolename = role['name']
                        break
                    else:
                        pass
            else:
                pass

            self.sgvs = {
                'pk': escape(self.pk),
                'pks': vals_to_strs(self.pks),
                'userid': escape(self.uid),
                'username': escape(self.username),
                'fullname': escape(self.fullname),
                'roleid': escape(self.rid),
                'rolename': escape(self.rolename),
            }

            self.cp = self.parser(self.conf)

            if self.cp.key_gid:
                self.conf['columns'][self.cp.key_gid]['enums'] = self.modules
            else:
                pass
        else:
            self.is_authenticated = False

    def parser(self, conf):
        return ConfParser(self.sc.loads(conf) if isinstance(conf, int) else conf, self.sgvs)

    def handle_request(self):
        raise NotImplementedError('subclasses of BaseTableUtils must provide a handle_request() method')

    def handle_select(self):
        cp = self.cp
        request = self.request

        if not cp.s_list:
            self.context['status'] = s.na
            return False

        conditions = self.conditions()

        total = self.fetchall(sql_common_select.format(sql_count, cp.obj, conditions, '', ''))[0][0]

        size = to_int(request.GET.get(self.k_size), 10)
        size = size if size in cp.sizes else 10
        currentpage = to_int(request.GET.get(self.k_currentpage), 1)

        if cp.views and currentpage * size > cp.views:
            currentpage = 1
        else:
            pass

        offset = (currentpage - 1) * size
        offset = offset if total > offset else 0

        if cp.enable_s_msg:
            self.sgvs['conditions'] = conditions
            message = self.fetchall(cp.get_sql(cp.enable_s_msg))[0][0]
        else:
            message = None

        res = self.fetchall(sql_common_select.format(
            cp.exprs(cp.d_a_list),
            cp.obj,
            conditions,
            self.orders(),
            sql_pagination.format(offset, size)
        ))

        self.result.update({
            'size': size,
            'total': total,
            'currentpage': currentpage,
            'table': zip_data(cp.d_a_list, res),
            'message': message
        })

    def handle_edit(self):
        cp = self.cp

        is_add = '0' == self.pk

        if self.is_super and is_add is False:
            status = self.default_status
            e_list = cp.e_list_super

        else:
            status = self.get_row_status(self.pk)
            e_list = cp.get_status_list('e', status)

        if not e_list or (not cp.enable_add and is_add):
            self.context['status'] = s.na
            return False

        res = self.handle_data(self.form_data, e_list, is_add is False)
        if isinstance(res, str):
            self.context['status'] = s.error
            self.context['message'] = res
            return False

        data = {}

        sql_cross = cp.e_list_cross.get('sql')
        if not self.is_super and sql_cross:
            vals = []
            for key in cp.e_list_cross.get('keys'):
                val = res.get(key)
                if val is None:
                    val = 'NULL'
                else:
                    val = escape(val)
                    res.pop(key)

                vals.append(val)
            sql_cross = cp.get_sql(sql_cross).format(*vals)
        else:
            sql_cross = None

        e_conf = cp.get_status_conf('e', status) if not self.is_super else {}

        default_set = e_conf.get('default_set') or {}
        func_b = e_conf.get('func_b')
        func_a = e_conf.get('func_a')
        msg = e_conf.get('msg')

        if not self.is_super:
            if self.handle_funcs(func_b) is False:
                self.context['status'] = s.error
                return False

            for col, val in default_set.items():
                data[col] = val

            if is_add:
                key_name = cp.key_iname
                key_dt = cp.key_idt
            else:
                key_name = cp.key_uname
                key_dt = cp.key_udt

            if key_name:
                data[cp.col(key_name)] = escape(self.username)
            else:
                pass

            if key_dt:
                data[cp.col(key_dt)] = sql_getdate
            else:
                pass
        else:
            pass

        for key, val in (res or {}).items():
            data[cp.col(key)] = escape(val)

        if is_add:
            if cp.key_gid:
                data[cp.col(cp.key_gid)] = escape(self.gid)
            else:
                pass

            sql = sql_common_insert.format(
                cp.table,
                sql_link.join(data.keys()),
                sql_link.join(data.values())
            )
        else:
            set_list = [sql_set.format(col, val) for col, val in data.items()]

            conditions = [self.limit_conditions(cp, False), sql_eq.format(cp.col(cp.key_id), escape(self.pk))]
            if not self.is_super and cp.key_status:
                conditions.append(sql_eq.format(cp.col(cp.key_status), escape(status)))
            else:
                pass

            sql = sql_common_update.format(
                cp.alias,
                sql_link.join(set_list),
                cp.table,
                sql_and.join(conditions)
            )

        if sql_cross:
            sql += ';\r\n' + sql_cross
        else:
            pass

        logger.info(sql)

        with connections[cp.db].cursor() as curs:
            curs.execute(sql)
            rowcount = curs.cursor.rowcount

            if is_add:
                curs.execute(sql_last_insert_id)
                self.pk = curs.fetchone()[0]
                self.sgvs['pk'] = escape(self.pk)
            else:
                pass

        if not self.is_super:
            if self.handle_funcs(func_a) is False:
                self.context['status'] = s.error
                return False
        else:
            pass

        if msg:
            self.context['message'] = msg.format(rowcount)
        else:
            pass

        return res

    def handle_verify(self):
        cp = self.cp
        request = self.request
        status = self.get_row_status(self.pks[0])

        v_list = cp.get_status_list('v', status)
        if v_list is False:
            self.context['status'] = s.na
            return False

        command = request.POST.get(self.k_command)
        is_valid_command = False
        v_cmds = cp.v_cmds_status.get(status, cp.v_cmds)
        for item in v_cmds:
            if item['command'] == command:
                is_valid_command = True
                break

        if is_valid_command is False:
            self.context['status'] = s.error
            self.context['message'] = '_T0007\f{}'.format(command)
            return False

        res = self.handle_data(self.form_data, v_list, True)
        if isinstance(res, str):
            self.context['status'] = s.error
            self.context['message'] = res
            return False

        v_conf = cp.get_status_conf('v', status)
        default_set = v_conf.get('default_set') or {}
        func_b = v_conf.get('func_b')
        func_a = v_conf.get('func_a')
        msg = v_conf.get('msg')

        if self.handle_funcs(func_b) is False:
            self.context['status'] = s.error
            return False

        data = {}
        for col, val in default_set.items():
            data[col] = val

        if cp.key_vname:
            data[cp.col(cp.key_vname)] = escape(self.username)
        else:
            pass

        if cp.key_vdt:
            data[cp.col(cp.key_vdt)] = sql_getdate
        else:
            pass

        for key, val in (res or {}).items():
            data[cp.col(key)] = escape(val)

        set_list = [sql_set.format(col, val) for col, val in data.items()]

        command_sql = cp.commands.get(command)
        if command_sql:
            set_list.append(command_sql)
        else:
            pass

        conditions = [self.limit_conditions(cp, False)]

        if cp.key_status:
            conditions.append(sql_eq.format(cp.col(cp.key_status), escape(status)))
        else:
            pass

        conditions.append(sql_in.format(cp.col(cp.key_id), vals_to_strs(self.pks)))

        sql = sql_common_update.format(
            cp.alias,
            sql_link.join(set_list),
            cp.table,
            sql_and.join(conditions)
        )

        logger.info(sql)

        with connections[cp.db].cursor() as curs:
            curs.execute(sql)
            rowcount = curs.cursor.rowcount

        if self.handle_funcs(func_a) is False:
            self.context['status'] = s.error
            return False

        if msg:
            self.context['message'] = msg.format(rowcount)
        else:
            pass

    def handle_data(self, data: dict, keys: list, is_update: bool):
        if not keys:
            return False

        form_data = {key: data[key] for key in keys if data.get(key) is not None}

        msg = is_valid(form_data, keys, self.cp.columns, is_update)

        return form_data if msg is True else msg

    def handle_funcs(self, funcs: Union[None, list]):
        if not isinstance(funcs, list):
            return True

        for opts in funcs:
            func = get_fn_by_path(opts['func'])
            args = opts.get('agrs', [])
            error_continue = opts.get('error_continue', False)
            if func(self, *args) is False and error_continue is False:
                return False
        return True

    def get_autocomplete_data(self, key: str):
        cp = self.cp
        request = self.request

        label = request.GET.get('label')
        value = vals_to_strs(request.GET.getlist('value[]', request.GET.getlist('value', [])), ['', 'NULL', None])

        autocomplete = cp.autocompletes.get(key)

        if autocomplete and (label or value):
            label_column = autocomplete['label']
            value_column = autocomplete['value']

            exprs = '{0}, {1}'.format(value_column, label_column)

            if label:
                condition = sql_like.format(label_column, '', escape(label, True))
            else:
                condition = sql_in.format(value_column, value)

            conditions = '({}){}({})'.format(
                self.limit_conditions(),
                sql_and_n,
                condition
            )

            sql = sql_common_select.format(
                exprs,
                cp.obj,
                conditions,
                sql_od.format(1),
                sql_pagination.format(0, 20)
            )
            data = self.fetchall(sql)
            return zip_data(['value', 'label'], data)
        return []

    def get_row_data(self, pk: Union[int, str], _type: str):
        if _type not in {'e', 'v'}:
            return {}

        cp = self.cp

        if _type == 'e' and self.request.GET.get(self.k_is_super, 'false') == 'true':
            status = self.default_status
            _list = cp.e_list_super
        else:
            status = self.get_row_status(pk)
            _list = cp.get_status_list(_type, status)

        if _list:
            if cp.key_status and cp.key_status not in _list:
                _list.append(cp.key_status)
            else:
                pass

            rowdata = self.get_row(pk, _list)

            if rowdata.get(cp.key_status, status) == status or status == self.default_status:
                return rowdata
            else:
                return {}
        else:
            return {}

    def get_row_status(self, pk: Union[int, str]):
        cp = self.cp
        request = self.request

        if pk and cp.key_status:
            if request.method == 'POST':
                status = request.POST.get(self.k_status)
            else:
                status = request.GET.get(self.k_status)

            status = status or self.get_cell(pk, cp.key_status)
        else:
            status = self.default_status
        return status

    def orders(self):
        cp = self.cp
        request = self.request

        orders = request.GET.get(self.k_orders, '').upper()
        if orders:
            order_dict = {}
            d_len = len(cp.d_a_list)
            for order in orders.split(','):
                if not order:
                    continue

                im = order.split()
                idx = to_int(im[0], -1)

                if 0 <= idx <= d_len:
                    order_dict[idx] = sql_desc if sql_desc in order else sql_asc

            if order_dict:
                orders = sql_link.join(['{} {}'.format(idx, method) for idx, method in order_dict.items()])
            else:
                orders = None
        else:
            orders = None
        return sql_od.format(orders or cp.orders)

    def limit_conditions(self, cp=None, is_search=True):
        if cp is None:
            cp = self.cp
        else:
            pass

        condition_list = ['1 = 1']

        # Enable gid
        # Ensure strong consistency of sub tables gid
        if cp.key_gid:
            # Ensure that the system properties of the main table and the sub table are consistent
            gids = [module['value'] for module in self.modules]
            gid = to_int(self.request.GET.get(self.k_gid))
            col = cp.col(cp.key_gid)

            if gid in gids:
                if gid != 0:
                    condition_list.append(sql_eq.format(col, gid))
                else:
                    pass
            else:
                if is_search and gid == 0 and cp.enable_all:
                    condition_list.append(sql_in.format(col, vals_to_strs(gids)))
                else:
                    condition_list.append(sql_eq.format(col, self.gid))
        else:
            pass

        default_condition = cp.sqls.get('default_condition')
        if default_condition:
            condition_list.append(default_condition)
        else:
            pass

        if cp.sqls.get('limit_condition'):
            condition_list.append(cp.get_sql('limit_condition'))
        else:
            pass

        return sql_and_n.join(condition_list)

    def conditions(self):
        """
        limit conditions + query conditions
        :return: Str
        """
        cp = self.cp
        request = self.request

        condition_list = []

        fulltext = request.GET.get(self.k_fulltext, '')

        for key in cp.s_list or []:
            _type = cp.col_type(key)
            _limit = cp.columns[key].get('limit', 1)

            # full text search is preferred
            if fulltext != '':
                values = fulltext
            else:
                if _type in ['enum', 'date', 'time', 'datetime']:
                    values = request.GET.getlist('{}[]'.format(key), request.GET.getlist(key))
                else:
                    values = request.GET.get(key)

            condition = self.get_condition(cp.col(key), values, _type, _limit)

            if condition:
                link_query = cp.columns[key].get('link_query')
                if link_query:
                    condition = cp.get_sql(link_query).format(condition)
                else:
                    pass
                condition_list.append(condition)
            else:
                pass

        logic_link = sql_or_n if fulltext != '' else sql_and_n
        conditions = logic_link.join(condition_list)
        limit_conditions = self.limit_conditions()
        return '({}){}({})'.format(limit_conditions, sql_and_n, conditions) if conditions else limit_conditions

    @staticmethod
    def get_condition(column: str, values: Union[str, list, None], _type: str, _limit: int) -> Union[str, None]:
        if not values:
            return None

        condition = ''

        if values == 'NULL':
            condition = '({0} IS NULL OR {0} = {1}{1})'.format(column, sql_quoted_identifier)
        elif values == 'NOT NULL':
            condition = '({0} IS NOT NULL AND {0} != {1}{1})'.format(column, sql_quoted_identifier)
        elif _type == 'num':
            values = ''.join(values.split())
            # Skip if there are illegal characters
            if re.sub(r'[0-9.,\-]', '', values):
                return None

            if ',' in values:
                strs = sql_link.join([value for value in values.split(',') if is_num(value)])
                if strs:
                    condition = sql_in.format(column, strs)
                else:
                    pass
            elif '-' in values:
                if '--' in values:
                    val_list = values.split('--')
                    start = val_list[0]
                    end = '-' + val_list[1]
                elif values.startswith('-') and values.count('-') == 2:
                    val_list = values.split('-')
                    start = '-' + val_list[0]
                    end = val_list[1]
                else:
                    val_list = values.split('-')
                    start = val_list[0]
                    end = val_list[1]

                tmp_list = []

                if start != '':
                    tmp_list.append(sql_gte.format(column, start))
                else:
                    pass

                if end != '':
                    tmp_list.append(sql_lte.format(column, end))
                else:
                    pass

                if tmp_list:
                    condition = '({})'.format(sql_and.join(tmp_list))
                else:
                    pass
            elif is_num(values):
                condition = sql_eq.format(column, values)
            else:
                pass
        elif _type in ['date', 'time', 'datetime']:
            # Full text search ignore
            if not isinstance(values, list) or len(values) != 2:
                return None
            condition = sql_between.format(column, escape(values[0]), escape(values[1]))
        elif _type == 'enum':
            # Full text search
            if not isinstance(values, list):
                return sql_like.format(column, '', escape(values, True))

            # Edit data is Single choice and query is multiple choices
            if _limit == 1:
                condition = sql_in.format(column, vals_to_strs(values))
            # Multiple fields are selected when entering data, and fuzzy matching is used when querying
            else:
                tmp_list = []
                for value in values:
                    tmp_list.append(sql_like.format(column, '', escape(value, True)))
                if tmp_list:
                    condition = '({})'.format(sql_and.join(tmp_list))
                else:
                    pass
        # file|remote|cascade|text|richtext treat as str
        else:
            if values[0] == '~':
                pat = ' NOT '
                values = ''.join(values[1:])
            else:
                pat = ''

            if ',' in values:
                strs = vals_to_strs(values.split(','), [''])
                if strs:
                    condition = sql_in.format(column + pat, strs)
                else:
                    pass
            elif '|' in values or '&' in values:

                if '|' in values:
                    sep = '|'
                    rel = sql_or
                else:
                    sep = '&'
                    rel = sql_and

                conditions = [sql_like.format(column, '', escape(value, True)) for value in values.split(sep)]

                if conditions:
                    condition = '{}({})'.format(pat, rel.join(conditions))
                else:
                    pass
            else:
                condition = sql_like.format(column, pat, escape(values, True))
        return condition

    def get_cell(self, pk: Union[int, str], key: str, cp: ConfParser = None) -> str:
        if cp is None:
            cp = self.cp
        else:
            pass

        res = self.get_row(pk, [key], cp)
        return res.get(key, '')

    def get_row(self, pk: Union[int, str], keys: list, cp: ConfParser = None) -> dict:
        if cp is None:
            cp = self.cp
        else:
            pass

        conditions = sql_eq.format(cp.col(cp.key_id), escape(pk))
        res = self.get_table(keys, conditions, cp, True)
        return res[0] if res else {}

    def get_table(self, keys: list, conditions: str = None, cp: ConfParser = None, is_zip: bool = False) -> list:
        if cp is None:
            cp = self.cp
        else:
            pass

        if conditions:
            conditions = '({}){}({})'.format(conditions, sql_and_n, self.limit_conditions(cp))
        else:
            conditions = self.limit_conditions(cp)

        sql = sql_common_select.format(cp.exprs(keys), cp.obj, conditions, '', '')
        data = self.fetchall(sql)
        return zip_data(keys, data) if is_zip else data

    def fetchall(self, sql: str, db: str = None) -> list:
        logger.info(sql)

        with connections[db or self.cp.db].cursor() as curs:
            curs.execute(sql)
            data = curs.fetchall()
        return data

    def execute(self, sql: str, db: str = None) -> None:
        logger.info(sql)

        with connections[db or self.cp.db].cursor() as curs:
            curs.execute(sql)

    def executemany(self, sql: str, data: list, db: str = None) -> None:
        logger.info(sql)

        with connections[db or self.cp.db].cursor() as curs:
            curs.executemany(sql, data)
