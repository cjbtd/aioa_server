from django.db import connections

from aioa.settings import s
from aioa.sql import *
from aioa.utils import to_int, zip_data, get_val_by_path
from apps.base.models import Config
from .table import BaseTableUtils
import json

regarg = 'idx'
regexp = re.compile(r'\$(?P<' + regarg + r'>\d+)')


def t_sum(tu: BaseTableUtils):
    cp = tu.cp
    request = tu.request

    key = request.GET.get('key')
    precision = to_int(request.GET.get('precision'), 0)

    if key in cp.d_a_list and cp.col_type(key) == 'num':
        expression = sql_isnull.format(cp.expr(key), 0)
        sql = sql_sum.format(precision, expression, cp.obj, tu.conditions())
        tu.context['message'] = tu.fetchall(sql)[0][0]
    else:
        tu.context['status'] = s.error
        tu.context['message'] = '_T0008'


def t_calc(tu: BaseTableUtils):
    cp = tu.cp
    request = tu.request
    expression = request.GET.get('expression', '')

    res = re.sub(r'(\+|-|\*|/|\(|\)|\$|\d|\.)', '', expression).strip()
    if res:
        tu.context['status'] = s.error
        tu.context['message'] = '_T0009\f【{}】'.format(res)
    else:
        display_list = [cp.expr(key) for key in cp.d_a_list if cp.col_type(key) == 'num']

        def replace(matched):
            return sql_isnull.format(display_list[int(matched.group(regarg))], 0)

        expression = regexp.sub(replace, expression)
        precision = to_int(request.GET.get('precision'), 0)

        sql = sql_sum.format(precision, expression, cp.obj, tu.conditions())
        tu.context['message'] = tu.fetchall(sql)[0][0]


def t_unique(tu: BaseTableUtils):
    cp = tu.cp
    request = tu.request

    keys = request.GET.getlist('keys[]')
    show_detail = request.GET.get('show_detail', 'false')

    expressions = cp.exprs(keys)

    conditions = tu.conditions()

    sql = sql_unique.format(expressions, cp.obj, conditions, sql_count, '')

    total = tu.fetchall(sql)[0][0]

    if show_detail == 'false':
        tu.result = None
        tu.context['message'] = total
    else:
        limit = to_int(get_val_by_path(cp.tools, 'unique.kwargs.limit'))

        sql = sql_unique.format(
            expressions,
            cp.obj,
            conditions,
            '*',
            sql_pagination.format(0, limit) if limit else ''
        )

        tu.result = zip_data(keys, tu.fetchall(sql))

        if limit and limit < total:
            tu.context['message'] = '_T0010\f{}\v{}'.format(total, limit)
        else:
            pass


def t_del(tu: BaseTableUtils):
    cp = tu.cp
    request = tu.request

    ids = request.GET.getlist('ids[]')

    conditions = [sql_in.format(cp.col(cp.key_id), vals_to_strs(ids) or 0)]
    limit_condition = get_val_by_path(cp.tools, 'del.kwargs.condition')
    if limit_condition:
        conditions.append(cp.get_sql(limit_condition))
    else:
        pass

    sql = sql_del.format(cp.table, sql_and.join(conditions))
    tu.execute(sql)
    tu.context['message'] = '_T0011'


def t_impd(tu: BaseTableUtils):
    cp = tu.cp
    request = tu.request

    e_list = cp.get_status_list('e', tu.default_status)
    if not e_list:
        tu.context['status'] = s.na
        return False

    data = json.loads(request.POST.get('data'))
    labels = data.pop(0)

    keys = []
    cols = []
    vals = []

    for label in labels:
        col = None
        for key in e_list:
            if label == key:
                col = cp.col(key)
                keys.append(key)
                break

        if col:
            cols.append(col)
            vals.append('%s')
        else:
            tu.context['status'] = s.error
            tu.context['message'] = '_T0013\f{}'.format(label)
            return False

    for key in e_list:
        if not get_val_by_path(cp.columns, '{}.null'.format(key), True) and key not in keys:
            tu.context['status'] = s.error
            tu.context['message'] = '_T0012\f{}'.format(key)
            return False

    if cp.key_gid:
        cols.append(cp.col(cp.key_gid))
        vals.append(escape(tu.gid))
    else:
        pass

    if cp.key_iname:
        cols.append(cp.col(cp.key_iname))
        vals.append(escape(tu.username))
    else:
        pass

    if cp.key_idt:
        cols.append(cp.col(cp.key_idt))
        vals.append(sql_getdate)
    else:
        pass

    sql = sql_common_insert.format(cp.table, sql_link.join(cols), sql_link.join(vals))
    tu.executemany(sql, data)
    tu.context['message'] = '_T0000\f{}'.format(len(data))


def t_expd(tu: BaseTableUtils):
    cp = tu.cp
    request = tu.request

    conditions = tu.conditions()

    sql = sql_common_select.format(sql_count, cp.obj, conditions, '', '')

    total = tu.fetchall(sql)[0][0]

    limit = to_int(get_val_by_path(cp.tools, 'expd.kwargs.limit'))

    sql = sql_common_select.format(
        cp.exprs(request.GET.getlist('keys[]')),
        cp.obj,
        conditions,
        tu.orders(),
        sql_pagination.format(0, limit) if limit else ''
    )

    tu.result = tu.fetchall(sql)

    if limit and limit < total:
        tu.context['message'] = '_T0014\f{}\v{}'.format(total, limit)
    else:
        pass


def t_enum(tu: BaseTableUtils):
    cp = tu.cp
    request = tu.request

    key = request.GET.get('key')
    keys = get_val_by_path(cp.tools, 'enum.kwargs.keys', {})
    if key not in keys:
        tu.context['status'] = s.na
        return False

    enums = request.POST.get('enums')

    idx = keys[key]
    obj = Config.objects.get(pk=idx)

    json_obj = json.loads(obj.conf)

    is_self = True
    tgt = get_val_by_path(json_obj, 'self.columns.{}.enums'.format(key))

    if tgt is None:
        is_self = False
        tgt = get_val_by_path(json_obj, 'columns.{}.enums'.format(key))
    else:
        pass

    if isinstance(tgt, list):
        if is_self:
            json_obj['self']['columns'][key]['enums'] = json.loads(enums)
        else:
            json_obj['columns'][key]['enums'] = json.loads(enums)
        json_str = json.dumps(json_obj, ensure_ascii=False)
    else:
        json_str = enums

        if tgt is not None:
            obj = Config.objects.get(pk=tgt.strip('#'))
        else:
            pass

    obj.conf = json_str
    obj.save()

    tu.sc.refresh('Config', Config.objects.filter(pk=idx))
    tu.context['message'] = '_T0015'


def t_chart(tu: BaseTableUtils):
    cp = tu.cp
    conf = cp.charts[get_val_by_path(cp.tools, 'chart.kwargs.chart')]

    datasets = {}
    for option, sets in conf['datasets'].items():
        dataset = []
        for opt in sets:
            sql = cp.get_sql(opt['sql'])
            keys = opt.get('keys')

            if opt.get('raw', False) is False:
                sql = sql_cte.format(
                    sql_common_select.format(cp.exprs(cp.d_a_list), cp.obj, tu.conditions(), '', ''),
                    sql
                )
            else:
                pass

            data = tu.fetchall(sql)
            dataset.append(zip_data(keys, data) if keys else data)
        datasets[option] = dataset
    tu.result = datasets


def handle_structure(tu: BaseTableUtils):
    cp = tu.cp
    request = tu.request

    if request.method == 'POST':
        contacts = request.POST.get('contacts')

        for job_name, pk_list in json.loads(contacts).items():
            sql = sql_update_contacts.format(escape(job_name), vals_to_strs(pk_list))
            tu.execute(sql)

        enums = request.POST.get('enums')
        idx = get_val_by_path(cp.tools, 'structure.kwargs.idx')

        obj = Config.objects.get(pk=idx)
        obj.conf = enums
        obj.save()

        tu.sc.refresh('Config', Config.objects.filter(pk=idx))

        tu.context['message'] = '_T0015'
    else:
        gid = get_val_by_path(cp.tools, 'structure.kwargs.gid') or 0
        tu.result = tu.fetchall(sql_get_contacts.format(gid))


def handle_attendance(tu: BaseTableUtils):
    cp = tu.cp
    request = tu.request

    range_list = request.GET.getlist('range[]')
    company_name = request.GET.get('companyName')

    sql = sql_attendance.format(escape(company_name), escape(range_list[0]), escape(range_list[1]))

    with connections[cp.db].cursor() as curs:
        curs.execute(sql)
        tu.result['da'] = curs.fetchall()
        curs.nextset()
        tu.result['qj'] = curs.fetchall()
        curs.nextset()
        tu.result['ldk'] = curs.fetchall()
        curs.nextset()
        tu.result['jjr'] = curs.fetchall()


tools_map = {
    'sum': t_sum,
    'calc': t_calc,
    'unique': t_unique,
    'del': t_del,
    'impd': t_impd,
    'expd': t_expd,
    'enum': t_enum,
    'chart': t_chart,
    'structure': handle_structure,
    'attendance': handle_attendance,
}


def handle_tools(tu: BaseTableUtils, tool):
    if tool in tu.cp.t_list and tool in tools_map:
        tools_map[tool](tu)
    else:
        tu.context['status'] = s.na
