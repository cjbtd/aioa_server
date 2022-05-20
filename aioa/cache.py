from typing import Any
from django.core.cache import cache
from .settings import CACHE_DEFAULT_TIMEOUT

KEY_HB = 'HB'
KEY_UNAME = 'UNAME'
KEY_CONFIG = 'CONFIG'
KEY_CONF = 'CONF'
KEY_OBJ = 'OBJ'
KEY_PATHS = 'PATHS'
KEY_MENUS = 'MENUS'
KEY_METAS = 'METAS'
KEY_ROLES = 'ROLES'
KEY_PRINTED = 'PRINTED'

conf = {
    'KEY': {
        'key': '{}:{}...',  # Multiple keywords are separated by colons
        'timeout': CACHE_DEFAULT_TIMEOUT,  # Default is CACHE_DEFAULT_TIMEOUT, and the unit is seconds
        'val': '...'  # Examples of values
    },
    KEY_HB: {
        # c_hb + request.user.username
        'key': 'c_hb:{}',
        # One minute
        'timeout': 60,
        # Judge whether the user is online
        'val': 0
    },
    KEY_UNAME: {
        # c_uname + request.user.username
        'key': 'c_uname:{}',
        # Online accounts are mutually exclusive
        'val': 'request.session.session_key'
    },
    KEY_CONFIG: {
        # c_config + cid
        'key': 'c_config:{}',
        # Cache conf and type
        'val': ('conf', 'type')
    },
    KEY_CONF: {
        # c_conf + base_config_id + over_config_id + spec_config_id + perm_config_id
        'key': 'c_conf:{}:{}:{}:{}',
        # Cache module merged conf
        'val': {},
    },
    KEY_OBJ: {
        # c_obj + config_id
        'key': 'c_obj:{}',
        'val': 'str',
    },
    KEY_PATHS: {
        # c_paths + request.user.username
        'key': 'c_paths:{}',
        # Store the routes that the account has access to, is set() object
        'val': {'path1', 'path2'}
    },
    KEY_MENUS: {
        # c_menus + request.user.username
        'key': 'c_menus:{}',
        # User menu
        'val': {
            'name': {
                'key': '',
                'index': '',
                'children': {
                    'name': {
                        'key': '',
                        'index': '',
                        'children': {}
                    }
                }
            }
        }
    },
    KEY_METAS: {
        # c_metas + request.user.username
        'key': 'c_metas:{}',
        # User menu's meta
        'val': {
            'path': {
                'mid': 'Menu id',
                'title': 'Last menu name',
                'tagName': 'Last menu name',
                'keepAlive': False,
                'modules': [
                    {
                        'label': '',
                        'value': '',
                        'cids': []
                    }
                ]
            }
        }
    },
    KEY_ROLES: {
        # c_roles + request.user.username
        'key': 'c_roles:{}',
        # User roles
        'val': [
            {
                'id': 'uid',
                'name': 'rolename',
            }
        ]
    },
    KEY_PRINTED: {
        'key': 'c_printed',
        'val': {'md51', 'md52'}
    },
}


class Cache:
    def __init__(self, key: str, *args):
        """
        Unified management cache conf and keep it simple

        """
        assert key in conf, 'The key 【{}】 not in the cache conf'.format(key)
        opts = conf[key]

        self.key = opts['key'].format(*args)
        self.timeout = opts.get('timeout', CACHE_DEFAULT_TIMEOUT)

    def get(self, default: Any = None) -> Any:
        """
        Get key's val, default is default

        :param default: Any, Default is None
        :return: Any
        """
        return cache.get(self.key, default)

    def set(self, val: Any) -> Any:
        """
        Set key's val

        :param val: Any, Require
        :return: val
        """
        cache.set(self.key, val, self.timeout)
        return val

    def keys(self) -> list:
        """
        Get keys's vals, Wildcards are supported

        :return: list[Any]
        """
        return cache.keys(self.key)

    def delete(self) -> int:
        """
        Delete keys by self.keys()

        :return: int, Number of keys affected
        """
        total = 0
        for key in self.keys():
            total += 1 if cache.delete(key) else 0
        return total


client = cache.client.get_client()
