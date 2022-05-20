from typing import Any, Generator
from functools import wraps
import os
import re
import time
import random
import hashlib
import importlib
import logging

logger = logging.getLogger('default')


def log_time(pos: str = ''):
    """
    Print number of function calls and execution time

    :param pos: Str, Function's position
    :return:
    """

    def decorator(func):
        times = 0

        @wraps(func)
        def wrapper(*args, **kwargs):
            nonlocal times
            begin = time.time()
            res = func(*args, **kwargs)
            end = time.time()
            times += 1
            print('pos: {}, func: {}, times: {}, cost: {}s'.format(pos, func.__name__, times, end - begin))
            return res

        return wrapper

    return decorator


def to_int(val: Any, default: int = 0):
    """
    Such as the function name

    :param val: Any
    :param default: Int, Default is 0
    :return: Int
    """
    val = str(val)
    return int(val) if val.isdigit() else default


def is_num(txt: Any) -> bool:
    """
    Judge whether the txt is a number(int|float)

    :param txt: Any
    :return: Bool
    """
    return not not re.match(r'^[-+]?\d+(\.\d+)?$', str(txt))


def int_to_str(iv: int, bn: int, bc: str) -> str:
    """
    Number to any base number by special strings

    :param iv: Int, Input value
    :param bn: Int, Base number, eg: 2, 8, 32
    :param bc: Str, Base chars
    :return: Str
    """
    return ((iv == 0) and '0') or (int_to_str(iv // bn, bn, bc).lstrip('0') + bc[iv % bn])


def get_random_str(length: int = 16) -> str:
    """
    Such as the function name

    :param length: Int, Output str's length, when length >= 16 get unique value
    :return: Str
    """
    chars = '0CHgJkoV3NLrtFjqmufl5ndX2zMGOPS1KEh8viWTsQAaIxcbyZ9p6ReDUYw47B' + random.choice(['cC', 'jJ', 'bB'])

    if length < 16:
        return ''.join(random.choice(chars) for _ in range(length))

    timestamp = int(time.time() * 10000000000) + int(random.choice('123456789'))
    _tmp = int_to_str(timestamp, 64, chars)
    surplus = length - len(_tmp)
    return ''.join(random.choice(chars) + _tmp[i] for i in range(surplus)) + _tmp[surplus:]


def get_random_num(length: int = 6) -> str:
    """
    Such as the function name

    :param length: Int, Output num's length
    :return: Str
    """
    return ''.join([str(random.randint(1, 9)) for _ in range(length)])


def get_ip(request) -> str:
    """
    Get ip by request

    :param request:
    :return: Str
    """
    return request.META.get('HTTP_X_FORWARDED_FOR') or request.META.get('REMOTE_ADDR') or ''


def zip_data(keys: list, data: list) -> list:
    """
    Such as the function name

    :param keys: List[key]
    :param data: list[val]
    :return: List[key:val, ...]
    """
    return [{key: val for key, val in zip(keys, row)} for row in data]


def save_file(attachment, root: str, subdir: str = '', prefix: str = '', suffix: str = '') -> tuple:
    """
    Such as the function name

    :param attachment: request attachment object
    :param root: Str, root directory
    :param subdir: Str, sub directory, any combination by %Y %m %d %H %M %S
    :param prefix: Str, filename prefix, any combination by %Y %m %d %H %M %S
    :param suffix: Str, filename suffix, any combination by %Y %m %d %H %M %S
    :return: Tuple[file fullpath name, filename]
    """
    absolute_path = os.path.join(root, time.strftime(subdir))
    if not os.path.exists(absolute_path):
        os.makedirs(absolute_path)

    filename = time.strftime(prefix) + attachment.name + time.strftime(suffix)
    fullname = os.path.join(absolute_path, filename)
    with open(fullname, 'wb+') as f:
        for chunk in attachment.chunks(chunk_size=4096):
            f.write(chunk)
    return fullname, filename


def get_file(filename: str, chunk_size: int = 4096, seek_id: int = 0) -> Generator:
    """
    get file by chunk

    :param filename: Str, File fullpath name
    :param chunk_size: Int, chunk size, default 4KB
    :param seek_id: Int, file block initial position, default 0B
    :return: Generator, Binary file blocks
    """
    with open(filename, 'rb') as fr:
        fr.seek(seek_id)
        while True:
            file = fr.read(chunk_size)
            if file:
                yield file
            else:
                break


def get_file_md5(filename: str, chunk_size: int = 4096) -> str:
    """
    Such as the function name

    :param filename: Str, File fullpath name
    :param chunk_size: Str, chunk size, default 4KB
    :return: Str, 32 chars
    """
    md = hashlib.md5()
    with open(filename, 'rb') as fr:
        while True:
            data = fr.read(chunk_size)
            if data:
                md.update(data)
            else:
                break
    return md.hexdigest()


def get_txt_md5(txt: Any) -> str:
    """
    Such as the function name

    :param txt: Any
    :return: Str, 32 chars
    """
    return hashlib.md5(str(txt).encode('utf-8')).hexdigest()


def get_fn_by_path(path: str):
    """
    Such as the function name

    :param path: Str, function relative path
    :return: Function
    """
    tmp = path.split('.')
    return getattr(importlib.import_module('.'.join(tmp[:-1])), tmp[-1])


def get_val_by_path(obj: Any, path: str, default: Any = None) -> Any:
    """
    Such as the function name

    :param obj: Dict | List | Tuple
    :param path: Str, e.g. a.0.b.1.c
    :param default: Any
    :return: Any
    """
    val = obj
    for idx in path.split('.'):
        if isinstance(val, dict):
            if idx in val:
                val = val[idx]
            elif idx.isdigit() and int(idx) in val:
                val = val[int(idx)]
            else:
                return default
        elif isinstance(val, list) or isinstance(val, tuple):
            if idx.isdigit() and len(val) > int(idx):
                val = val[int(idx)]
            else:
                return default
        else:
            return default
    return val


def merge_dict(old_dict, new_dict) -> None:
    """
    Such as the function name

    :param old_dict: Dict
    :param new_dict: Dict
    :return:
    """
    assert isinstance(old_dict, dict) and isinstance(new_dict, dict), 'Only dict objects can be merged'

    for key, val in new_dict.items():
        old_val = old_dict.get(key)
        if isinstance(old_val, dict) and isinstance(val, dict):
            merge_dict(old_val, val)
        else:
            old_dict[key] = val


def merge_dicts(*args) -> None:
    """
    Such as the function name

    :param args: List[Dict]
    :return:
    """
    assert len(args) > 1, 'At least two dict objects are required'

    old_dict = args[0]
    for new_dict in args[1:]:
        merge_dict(old_dict, new_dict)


def string_to_dict(string: str, val: str, idx: int = 1, opts: list = None) -> tuple:
    """
    string to dict by separator

    :param string: Str, Input string, e.g.: name1//name2 /name3
    :param val: Str, Key's val
    :param idx: Int, Count
    :param opts: List, [_sep, _key, _index, _children] = ['/', 'key', 'index', 'children']
    :return: Tuple[Dict, Int]
    """
    assert isinstance(idx, int), 'idx must be integer'

    if opts is None:
        opts = ['/', 'key', 'index', 'children']
    else:
        pass

    [_sep, _key, _index, _children] = opts

    names = string.split(_sep)
    names.reverse()

    name_dict = {}
    for name in names:
        name = name.strip()
        if not name:
            continue

        idx += 1
        key_str = str(idx)

        if name_dict:
            name_dict = {
                name: {
                    _key: key_str,
                    _children: name_dict
                }
            }
        else:
            name_dict[name] = {
                _key: key_str,
                _index: val
            }
    return name_dict, idx


def list_dict_to_list_str(list_dict: list, list_str: list = None, val: str = '', link: str = ' / ') -> list:
    """
    List[Dict] to List[Str]

    :param list_dict: List[Dict], [{'value': '', 'disabled': '', 'children': [...]}]
    :param list_str: List[Str], The result
    :param val: Str, Temp string
    :param link: Str, The symbol of link string
    :return: List[Str]
    """
    if list_str is None:
        list_str = []

    for item in list_dict:
        if item.get('disabled'):
            continue

        tmp = val + item.get('value', '')

        children = item.get('children')
        if children and isinstance(children, list):
            list_dict_to_list_str(children, list_str, tmp + link)
        else:
            list_str.append(tmp)
    return list_str


def keys_to_dict(keys: list, vals: dict) -> dict:
    """
    Such as the function name

    :param keys: List, Some key
    :param vals: Dict, Key value pair
    :return: Dict
    """
    return {key: vals.get(key) for key in keys}
