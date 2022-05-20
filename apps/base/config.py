from typing import Any
from django.db import connections
from django.http import FileResponse
from urllib.parse import quote
from aioa.settings import v, FILES_ROOT
from aioa.utils import logger, get_file, get_val_by_path, merge_dict, merge_dicts, string_to_dict
from aioa.cache import Cache, KEY_CONFIG, KEY_CONF, KEY_OBJ, KEY_PATHS, KEY_MENUS, KEY_METAS, KEY_ROLES
from aioa.sql import escape, vals_to_strs, sql_eq, sql_wrap, sql_get_modules, sql_conf_relations
from .models import *
from pathlib import Path
import json
import re

pattern = '"#{}#"'
regarg = 'cid'
regexp = re.compile(r'"#(?P<' + regarg + r'>\d+)#"( *: *"#0#")?')


class SystemConfig:
    """
    Rebuild conf to Object or Str, and cache it
    """

    def __init__(self, user: str = None):
        self.user = user

    def _replace(self, matched) -> str:
        """
        Regex substitution function, return referenced conf

        :param matched:
        :return: Str
        """
        cid = matched.group(regarg)

        logger.debug(cid)

        conf, _type = self.get_config(cid)

        if _type in JSON_ITEM_TYPES:
            conf = conf.strip()[1:-1]
        elif _type in JSON_TEXT_TYPES:
            conf = json.dumps({"tmp": conf}, ensure_ascii=False)[8:-1]
        else:
            pass
        return self._restore(conf)

    def _restore(self, txt: str) -> str:
        """
        Restore conf

        :param txt: Str, conf
        :return: Str
        """
        return regexp.sub(self._replace, txt)

    def _rebuild(self, txt: str) -> str:
        """
        Rebuild conf

        :param txt: Str, conf
        :return: Str
        """
        return self._restore(txt)

    def loads(self, cid: int) -> Any:
        """
        Parser conf to Object or Str

        :param cid: Int, Config.id
        :return: Object
        """
        conf, _type = self.get_config(cid)

        if _type in REFERABLE_TYPES:
            return json.loads(self._rebuild(conf))

        if _type in JSON_TYPES:
            return json.loads(conf)

        return conf

    @staticmethod
    def format_json(txt: str, indent: int = None) -> str:
        """
        Unfold or zip json str

        :param txt: Str
        :param indent: Int|None, None is zip, otherwise is unfold
        :return: Str
        """
        return json.dumps(json.loads(txt), ensure_ascii=False, indent=indent)

    @staticmethod
    def get_relation_ids(fcid: int) -> set:
        """
        Get relation ids by Config.id

        :param fcid: Int, first Config.id
        :return: set()
        """
        rcids = [fcid]
        for cid in rcids:
            for rcid in Config.objects.values_list('id', flat=True).filter(conf__contains=pattern.format(cid)):
                rcids.append(rcid)
        return set(rcids)

    @staticmethod
    def cache_config(cid: int, val: Any = None) -> Any:
        """
        Cache Config

        :param cid: Int, Config.id
        :param val: List[Str, Str], ['conf', 'type']
        :return: val
        """
        return Cache(KEY_CONFIG, cid).set(val or Config.objects.values_list('conf', 'type').get(pk=cid))

    def get_config(self, cid: int) -> list:
        """
        Get Config

        :param cid: Int, Config.id
        :return: List[Str, Str], ['conf', 'type']
        """
        return Cache(KEY_CONFIG, cid).get() or self.cache_config(cid)

    def load_conf(self, bcid: int, ocid: int, scid: int, pcid: int, force: bool = False) -> Any:
        """
        Merge and cache conf

        :param bcid: Int, base Config.id
        :param ocid: Int, over Config.id
        :param scid: Int, spec Config.id
        :param pcid: Int, perm Config.id
        :param force: Bool, force merge
        :return: Object
        """
        conf = Cache(KEY_CONF, bcid, ocid, scid, pcid).get()

        if conf is None or force:
            conf = {}
            merge_dicts(conf, self.loads(bcid), self.loads(ocid), self.loads(scid), self.loads(pcid))
            Cache(KEY_CONF, bcid, ocid, scid, pcid).set(conf)
        else:
            pass
        return conf

    def load_menu(self, key: str = None) -> Any:
        """
        Load menu by user, return key

        :param key: Str, the val is one of [PATHS|MENUS|METAS]
        :return: Object
        """
        paths = set()
        menus = {}
        metas = {}

        sql = sql_get_modules.format(sql_eq.format(sql_wrap.format('user'), escape(self.user)))

        logger.debug(sql)

        with connections['default'].cursor() as curs:
            curs.execute(sql)
            data = curs.fetchall()

        idx = 0
        for row in data:
            idx += 1
            mid, path, name, meta, relations, label, value, bcid, ocid, scid, pcid = row[4:]

            if path not in paths:
                paths.add(path)

                relations = relations or ''
                for rel in relations.split(v.sep_menu_relation_url):
                    paths.add(rel.strip())

                menu, idx = string_to_dict(name, path, idx)
                merge_dict(menus, menu)

                last_name = name.split(v.sep_menu_path)[-1]
                _meta = {'mid': mid, 'title': last_name, 'tagName': last_name, 'keepAlive': False, 'modules': []}
                merge_dict(_meta, json.loads(meta))
                metas[path] = _meta
            else:
                pass

            metas[path]['modules'].append({'label': label, 'value': value, 'cids': [bcid, ocid, scid, pcid]})

        Cache(KEY_PATHS, self.user).set(paths)
        Cache(KEY_MENUS, self.user).set(menus)
        Cache(KEY_METAS, self.user).set(metas)

        return not key or Cache(key, self.user).get()

    def refresh(self, cls: str, queryset=None) -> int:
        """
        Module conf and perm separation
            1. When conf changes, only find the related conf and reload
            2. When perm changes, empty PATHS,MENUS,METAS caches

        :param queryset: Object, Model.objects.filter()
        :param cls: Str, the val is one of the [Config|Menu|Module|Role|RolePerm|UserRole|UserPerm]
        :return: Int, Number of affected
        """
        if cls == 'Config':
            cids = set()
            for config in queryset:
                cid = config.id
                Cache(KEY_CONFIG, cid).set([config.conf, config.type])
                cids.update(self.get_relation_ids(cid))

            for cid in cids:
                Cache(KEY_OBJ, cid).delete()

            sql = sql_conf_relations.format(vals_to_strs(cids))

            logger.debug(sql)

            with connections['default'].cursor() as curs:
                curs.execute(sql)
                data = curs.fetchall()

            for row in data:
                self.load_conf(*row, True)

            total = len(cids)
        else:
            total = self.clear()
        return total

    def clear(self) -> int:
        """
        Clear cache for user, if user is None then clear all

        :return: Int, Total
        """
        total = 0
        for key in [KEY_PATHS, KEY_MENUS, KEY_METAS, KEY_ROLES]:
            total += Cache(key, self.user or '*').delete()
        return total

    def get(self, key: str) -> Any:
        """
        Get user's [PATHS|MENUS|METAS]

        :param key: Str, the val is one of the [PATHS|MENUS|METAS]
        :return: Objcet
        """
        # Due to the user's [PATHS|MENUS|METAS] cannot be empty, so direct use "or" instead of judge whether it is None
        return Cache(key, self.user).get() or self.load_menu(key)

    def get_module(self, path: str, gid: int = None) -> tuple:
        """
        Get Module conf by user, default is first Module

        :param path: Str, url
        :param gid: Int, Module.value
        :return: Tuple, (Menu.id, Module.value, conf, modules)
        """
        metas = self.get(KEY_METAS)
        assert path in metas, 'No Permission：{}'.format(path)

        mid = metas[path]['mid']
        modules = metas[path]['modules']

        cids = None
        for module in modules:
            if gid == module['value']:
                cids = module['cids']
            else:
                pass

        if cids is None:
            gid = modules[0]['value']
            cids = modules[0]['cids']
        else:
            pass

        return mid, gid, self.load_conf(*cids), modules

    def get_obj(self, path: str) -> Any:
        """
        Get obj by path in maps's Config.id

        :param path: Str, maps's path, such as message or base.notices
        :return: Object|Str
        """
        maps = Cache(KEY_OBJ, DEFAULT_MAPS_CONFIG_ID).get()
        if maps is None:
            maps = self.loads(DEFAULT_MAPS_CONFIG_ID)
            Cache(KEY_OBJ, DEFAULT_MAPS_CONFIG_ID).set(maps)
        else:
            pass

        idx = get_val_by_path(maps, path, DEFAULT_CONF_CONFIG_ID)

        obj = Cache(KEY_OBJ, idx).get()
        if obj is None:
            obj = self.loads(idx)
            Cache(KEY_OBJ, idx).set(obj)
        else:
            pass
        return obj


def download_file(fileinfo: str) -> FileResponse:
    """
    Get file response by md5 from table cell value

    :param fileinfo: str, md5:::name
    :return:
    """
    md5, _, filename = fileinfo.partition(v.link_name)
    if is_exist_file(md5):
        file = get_file(FILES_ROOT / md5)
        filename = filename
    else:
        file = 0
        filename = 'error'

    response = FileResponse(file)
    response['Content-Type'] = 'application/octet-stream'
    response['Content-Disposition'] = 'attachment;filename="{}"'.format(quote(filename))
    return response


def is_exist_file(s_md5: str) -> bool:
    """
    Check whether the file exists by md5 in FILES_ROOT

    :param s_md5: Str, MD5 value
    :return: Bool
    """
    if s_md5 and len(s_md5) == 32 and '.' not in s_md5:
        b_exist = Path(FILES_ROOT / s_md5).is_file()
    else:
        b_exist = False
    return b_exist
