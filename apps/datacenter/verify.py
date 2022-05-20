from typing import Union
import re


def is_valid(form_data: dict, keys: list, columns, is_update: bool) -> Union[bool, str]:
    """
    Verify form_data validity

    :param form_data: Dict, { key: val([None, 'NULL', '...']) }
    :param keys: List
    :param columns: Dict, keys conf
    :param is_update: Bool, Insert or update
    :return: Bool|Str
    """
    res = True

    for key in keys:
        kwargs = columns[key]
        _type = kwargs.get('type', 'str')

        null = kwargs.get('null', True)  # allow null

        # sizes = kwargs.get('sizes')
        # limit = kwargs.get('limit', 1)  # [enum|remote|file] quantity limit

        ranges = kwargs.get('ranges')  # [num] is the numeric range, and others are the character length range
        regexs = kwargs.get('regexs') or []  # regular expression list, any one matched is valid

        val = form_data.get(key)  # val can only be None|Str('NULL', '...')

        if isinstance(val, int) or isinstance(val, float):
            val = str(val)
        else:
            pass

        # If val is None, this means that the front does not pass a value, there are two situations
        if val is None and is_update:
            continue
        else:
            pass

        if val in {None, 'NULL'}:
            if null:
                continue
            else:
                pass
            return '_T0003\f{}'.format(key)

        # Do not check: [date|time|datetime|file|enum|cascade|remote]
        if _type in {'date', 'time', 'datetime', 'file', 'enum', 'remote', 'cascade'}:
            continue
        else:
            pass

        # Check validity and range: num
        # Check validity and length: str|text|richtext

        # Check validity using regular
        if _type == 'num':
            regexs.append(('_T0004', r'^[-+]?\d+(\.\d+)?$', 'float'))
        else:
            pass

        if regexs:
            for msg, reg, _ in regexs:
                if re.match(re.compile(reg), val):
                    res = True
                    break
                else:
                    res = '{}\f{}'.format(msg, key)

            if res is not True:
                return res
        else:
            pass

        # Check the value range or string length range
        if _type == 'num':
            msg = '_T0005'
        else:
            msg = '_T0006'
            val = len(val)  # Str checked, converted to length

        if ranges:
            c_min, c_max = ranges
            c_min_limit = len(c_min) != 0
            c_max_limit = len(c_max) != 0

            if (c_min_limit and float(val) < float(c_min)) or (c_max_limit and float(val) > float(c_max)):
                c_min = c_min if c_min_limit else '~'
                c_max = c_max if c_max_limit else '~'
                return '{}\f{}\v{}\v{}'.format(msg, key, c_min, c_max)
        else:
            pass
    return res
