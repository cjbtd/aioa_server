from aioa.sql import escape
from aioa.utils import zip_data
from .table import BaseTableUtils


def handle_relations(tu: BaseTableUtils, pk: str, relation: str) -> bool:
    cp = tu.cp

    if relation and (relation not in cp.r_list or relation not in cp.relations):
        return False

    _list = [relation] if relation else cp.r_list

    row = tu.get_row(pk, cp.d_a_list)

    if not row:
        return False

    for key in _list:
        opts = cp.relations[key]
        _type = opts.get('type', 'rTable')
        kwargs = opts.get('kwargs')

        if _type == 'rTable':
            result = handle_table(tu, kwargs, row)
        elif _type == 'rChart':
            result = handle_chart(tu, kwargs, row)
        elif _type == 'rLayout':
            result = handle_layout(tu, kwargs, row)
        else:
            result = None
        tu.result[key] = result
    return True


def handle_table(tu: BaseTableUtils, kwargs: dict, row: dict):
    cp = tu.parser(kwargs['conf'])

    condition = cp.get_sql(kwargs['condition']).format(*[escape(row[key]) for key in kwargs.get('keys', [])])
    data = tu.get_table(cp.d_a_list, condition, cp, True)

    if data:
        return {'columns': cp.columns, 'd_r_list': cp.d_r_list, 'data': data, 'config': cp.config}
    else:
        return None


def handle_chart(tu: BaseTableUtils, kwargs: dict, row: dict):
    cp = tu.cp
    conf = cp.charts[kwargs['chart']]

    datasets = {}
    for option, sets in conf['datasets'].items():
        dataset = []
        for opt in sets:
            sql = cp.get_sql(opt['sql']).format(**{key: escape(val) for key, val in row.items()})
            keys = opt.get('keys')

            data = tu.fetchall(sql)
            dataset.append(zip_data(keys, data) if keys else data)
        datasets[option] = dataset
    return datasets


def handle_layout(tu: BaseTableUtils, kwargs: dict, row: dict):
    cp = tu.cp
    conf = cp.layouts[kwargs['layout']]

    datasets = {}
    for key, opt in conf.get('subData', {}).items():
        sql = cp.get_sql(opt['sql']).format(**{key: escape(val) for key, val in row.items()})
        keys = opt.get('keys')
        data = tu.fetchall(sql)

        datasets[key] = zip_data(keys, data) if keys else data
    return datasets
