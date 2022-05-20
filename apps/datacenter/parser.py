from typing import Union
from aioa.sql import sql_wrap, sql_quoted_identifier, sql_link_n
from aioa.utils import merge_dict, get_val_by_path


class ConfParser:
    """
    Parser conf and set default value
    """

    def __init__(self, conf: dict, sgvs: dict = None):
        assert isinstance(conf, dict), 'conf is not a legal variable: {}'.format(conf)

        # Set the conf with the highest priority
        merge_dict(conf, conf.get('self') or {})
        self.conf = conf

        # Database related
        self.db = conf.get('db', 'default')
        self.alias = conf.get('alias', 'a')

        obj = conf.get('obj')
        assert isinstance(obj, str), 'obj is not a legal variable: {}'.format(obj)

        objs = obj.split()
        objs.insert(1, self.alias)

        self.obj = ' '.join(objs)
        self.table = conf.get('table', objs[0])
        self.orders = conf.get('orders', '1 DESC')
        self.book = conf.get('book')

        self.sqls = conf.get('sqls') or {}
        self.views = conf.get('views', 0)
        self.sizes = conf.get('sizes', [5, 10, 20, 50, 100])

        # Some front config
        self.config = conf.get('config', {})

        # System default key
        self.key_id = conf.get('key_id', 'id')
        self.key_gid = conf.get('key_gid', 'gid')
        self.key_status = conf.get('key_status', 'status')
        self.key_iname, self.key_idt = conf.get('key_i', ['iname', 'idt']) or [False, False]
        self.key_uname, self.key_udt = conf.get('key_u', ['uname', 'udt']) or [False, False]
        self.key_vname, self.key_vdt = conf.get('key_v', ['vname', 'vdt']) or [False, False]

        # System global variables
        merge_dict(sgvs, conf.get('sgvs', {}))
        self.sgvs = sgvs

        # Some control config
        df = conf.get('enable_df', False)
        if df is True:
            df = {"TO": "TO", "CC": "CC", "SIGN": "SIGN", "STAMP": "STAMP"}
        else:
            pass

        self.enable_df = df

        self.enable_add = conf.get('enable_add', True)
        self.enable_all = conf.get('enable_all', True)  # Allow viewing of all groups

        self.enable_s_msg = conf.get('enable_s_msg', False)
        self.enable_e_mail = conf.get('enable_e_mail', False)
        self.enable_v_mail = conf.get('enable_v_mail', False)

        self.autocompletes = conf.get('autocompletes') or {}

        # Core config
        self.charts = conf.get('charts') or {}
        self.layouts = conf.get('layouts') or {}

        self.columns = conf.get('columns')
        assert isinstance(self.columns, dict), 'columns is not a legal variable: {}'.format(self.columns)

        self.tools = conf.get('tools') or {}  # tools maybe null
        self.relations = conf.get('relations') or {}  # relations maybe null

        # Some perm config
        t_list = conf.get('t_list', True)
        self.t_list = list(self.tools.keys()) if t_list is True else t_list

        r_list = conf.get('r_list', True)
        self.r_list = list(self.relations.keys()) if r_list is True else r_list

        self.s_list = self.get_enabled_columns('s_list')
        self.d_a_list = self.get_enabled_columns('d_a_list')
        self.d_d_list = [key for key in self.get_enabled_columns('d_d_list') if key in self.d_a_list] or self.d_a_list
        self.d_r_list = [key for key in self.get_enabled_columns('d_r_list') if key in self.d_a_list] or self.d_a_list

        # Edit related config
        self.e_conf = conf.get('e_conf', {
            'default_set': self.key_status and {self.col(self.key_status): '{0}0{0}'.format(sql_quoted_identifier)},
        })
        if self.e_conf.get('msg') is None:
            self.e_conf['msg'] = '_T0000\f{}'
        else:
            pass

        self.e_conf_status = conf.get('e_conf_status', {})
        self.e_list = self.get_enabled_columns('e_list')
        self.e_list_status = conf.get('e_list_status', True)

        self.e_list_super = conf.get('e_list_super', [])
        self.e_list_cross = conf.get('e_list_cross', {})

        # Verify related config
        self.commands = conf.get('commands') or {}
        self.dataflows = conf.get('dataflows') or {}
        self.v_cmds = conf.get('v_cmds', [
            {
                'label': [
                    '审核',
                    'Verify'
                ],
                'command': '0',
                'type': 'danger',
                'tips': [
                    '这意味着数据有效，请确认是否继续？',
                    'This means that the data is valid. Are you sure you want to continue?'
                ]
            }
        ])
        self.v_cmds_status = conf.get('v_cmds_status', {})

        self.v_conf = self.conf.get('v_conf', {
            'default_set': self.key_status and {self.col(self.key_status): '{0}1{0}'.format(sql_quoted_identifier)},
        })
        if self.v_conf.get('msg') is None:
            self.v_conf['msg'] = '_T0000\f{}'
        else:
            pass

        self.v_conf_status = self.conf.get('v_conf_status', {})
        self.v_list = self.get_enabled_columns('v_list')
        self.v_list_status = self.conf.get('v_list_status', {'0': self.v_list})

    def get_enabled_columns(self, attr) -> list:
        """
        Gets enabled columns according to the attr

        :param attr: Str, [s_list|e_list|v_list|d_a_list|d_d_list|d_r_list]
        :return: List
        """
        enabled = ('s', 'e', 'a', 'd', 'r')  # Exclude verify(v)
        t = attr.split('_')[-2]  # [s|e|v|a|d|r]
        val = self.conf.get(attr, True)
        return [key for key, val in self.columns.items() if t in val.get('enabled', enabled)] if val is True else val

    def get_status_conf(self, attr, status) -> dict:
        """
        Get edit/verify conf by status

        :param attr: Str, [e|v]
        :param status: Str
        :return: Dict
        """
        conf = getattr(self, '{}_conf_status'.format(attr)).get(status, {})
        merge_dict(conf, getattr(self, '{}_conf'.format(attr)))
        return conf

    def get_status_list(self, attr, status) -> Union[list, bool]:
        """
        Get edit/verify list by status

        :param attr: Str, [e|v]
        :param status: Str
        :return: List|False
        """
        list_status = getattr(self, '{}_list_status'.format(attr))

        if list_status is False:
            return False

        if list_status is True:
            return getattr(self, '{}_list'.format(attr))

        _list = list_status.get(status, True if attr == 'e' else False)
        return getattr(self, '{}_list'.format(attr)) if _list is True else _list

    def get_sql(self, sql: str) -> str:
        """
        Get sql and fill sgvs

        :param sql: Str, sql or sqls.key
        :return: Str
        """
        return self.sqls.get(sql, sql).format(**self.sgvs)

    def col_type(self, key: str) -> str:
        """
        Get column type, default is str

        :param key: Str, columns.key
        :return: Str
        """
        return self.columns[key].get('type', 'str')

    def col(self, key: str, is_wrap=True) -> str:
        """
        Get column name, default is key name

        :param key: Str, columns.key
        :param is_wrap: Bool, wrap custom name
        :return: Str
        """
        name = self.columns[key].get('name', key)
        return sql_wrap.format(name) if is_wrap else name

    def cols(self, _list: list) -> str:
        """
        Get column list by _list

        :param _list: List, [Key, ...]
        :return: Str
        """
        return sql_link_n.join([self.col(key) for key in _list])

    def expr(self, key: str) -> str:
        """
        Get column expression

        :param key: Str, columns.key
        :return: Str
        """
        return self.get_sql(self.columns[key].get('expression') or self.col(key))

    def exprs(self, _list: list) -> str:
        """
        Get query expressions

        :param _list: List, columns.key list
        :return: Str
        """
        return sql_link_n.join([self.expr(key) for key in _list])

    def opts(self) -> dict:
        """
        Get client options and filter some option

        :return: Dict
        """
        for key in self.relations:
            if get_val_by_path(self.relations, '{}.kwargs.conf'.format(key)) is not None:
                self.relations[key]['kwargs'] = None
            else:
                pass

        return {
            'views': self.views,
            'sizes': self.sizes,
            'config': self.config,
            'key_id': self.key_id,
            'key_gid': self.key_gid,
            'key_status': self.key_status,
            'enable_df': self.enable_df,
            'enable_all': self.enable_all,
            'enable_add': self.enable_add,
            'enable_e_mail': self.enable_e_mail,
            'enable_v_mail': self.enable_v_mail,
            'charts': self.charts,
            'layouts': self.layouts,
            'tools': self.tools,
            'columns': self.columns,
            'relations': self.relations,
            't_list': self.t_list,
            'r_list': self.r_list,
            's_list': self.s_list,
            'd_a_list': self.d_a_list,
            'd_d_list': self.d_d_list,
            'd_r_list': self.d_r_list,
            'e_list': self.e_list,
            'e_list_status': self.e_list_status or False,
            'e_list_super': self.e_list_super,
            'v_list': self.v_list,
            'v_list_status': self.v_list_status or False,
            'v_cmds': self.v_cmds,
            'v_cmds_status': self.v_cmds_status,
        }
