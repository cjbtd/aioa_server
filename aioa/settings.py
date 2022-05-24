"""
Django settings for aioa project.

Generated by 'django-admin startproject' using Django 4.0.4.

For more information on this file, see
https://docs.djangoproject.com/en/4.0/topics/settings/

For the full list of settings and their values, see
https://docs.djangoproject.com/en/4.0/ref/settings/
"""
from pathlib import Path
import os

SECRET_KEY = 'django-insecure-atvh0mhah9g#g))s@qk#tq&%ege#$m_dn_-mda$2!-r(oa-=%i'
ALLOWED_HOSTS = ['*']


def init_dir(path: Path) -> Path:
    Path(path).mkdir(parents=True, exist_ok=True)
    return path


# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

DEBUG = BASE_DIR.__str__().startswith('D:')

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'corsheaders',
    'ckeditor',
    'ckeditor_uploader',
    'apps.base.apps.BaseConfig',
    'apps.chat.apps.ChatConfig'
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'aioa.middleware.ControlMiddleware',
]

# Corsheaders middleware args
CORS_ALLOW_CREDENTIALS = True
CORS_ORIGIN_ALLOW_ALL = True

CSRF_TRUSTED_ORIGINS = ['http://localhost:8082', 'https://www.chenjiabintd.com', 'http://www.chenjiabintd.com']

ROOT_URLCONF = 'aioa.urls'

WSGI_APPLICATION = 'aioa.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'aioa',
        'USER': 'aioa',
        'PASSWORD': 'aioa',
        'HOST': '172.16.0.7',
        'PORT': 3306,
    }
}

DATABASE_CONNECTION_POOLING = True
DEFAULT_AUTO_FIELD = 'django.db.models.AutoField'

CACHE_DEFAULT_TIMEOUT = None
CACHE_SERVER = '127.0.0.1'
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://{}:6379/3'.format(CACHE_SERVER),
        'OPTIONS': {
            'CONNECTION_POOL_KWARGS': {'max_connections': 1024}
        },
        'TIMEOUT': CACHE_DEFAULT_TIMEOUT
    },
    'session': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://{}:6379/4'.format(CACHE_SERVER),
        'OPTIONS': {
            'CONNECTION_POOL_KWARGS': {'max_connections': 1024}
        },
        'TIMEOUT': CACHE_DEFAULT_TIMEOUT
    }
}

SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'session'
SESSION_COOKIE_AGE = 1 * 24 * 60 * 60  # one day
SESSION_SAVE_EVERY_REQUEST = False
SESSION_EXPIRE_AT_BROWSER_CLOSE = True

LANGUAGE_CODE = 'zh-Hans'
TIME_ZONE = 'Asia/Shanghai'
USE_I18N = True
USE_L10N = True
USE_TZ = False

STATIC_URL = '/static/'
MEDIA_URL = '/media/'

# Directory
LOG_DIR = init_dir(BASE_DIR / 'logs')
FILES_ROOT = init_dir(BASE_DIR / 'files')
MEDIA_ROOT = init_dir(BASE_DIR / 'media')
STATIC_DIR = init_dir(BASE_DIR / 'static')
TEMPLATES_ROOT = init_dir(BASE_DIR / 'templates')

if DEBUG:
    STATICFILES_DIRS = [STATIC_DIR]
else:
    STATIC_ROOT = STATIC_DIR

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [TEMPLATES_ROOT],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

# Logger info
# CRITICAL = 50
# ERROR = 40
# WARNING = 30
# INFO = 20
# DEBUG = 10
# NOTSET = 0
LOG_LEVEL = 'DEBUG' if DEBUG else 'INFO'
LOG_HANDLERS = 'console' if DEBUG else 'file'
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'default': {
            'format': '~->->->->->] [%(asctime)s] [%(levelname)s] [%(pathname)s %(funcName)s %(lineno)d] [%(message)s'
        },
    },
    'handlers': {
        'console': {
            'level': LOG_LEVEL,
            'class': 'logging.StreamHandler',
            'formatter': 'default',
        },
        'file': {
            'level': LOG_LEVEL,
            'class': 'logging.FileHandler',
            'formatter': 'default',
            'filename': '{}/db.{}.log'.format(LOG_DIR, os.getpid()),
            'encoding': 'utf-8'
        },
        'fileTimed': {
            'level': LOG_LEVEL,
            'class': 'logging.handlers.TimedRotatingFileHandler',
            'formatter': 'default',
            'filename': '{}/db.{}.log'.format(LOG_DIR, os.getpid()),
            'when': 'D',
            'interval': 1,
            'encoding': 'utf-8'
        },
    },
    'loggers': {
        'default': {
            'handlers': [LOG_HANDLERS],
            'level': LOG_LEVEL,
            'propagate': False,
        }
    },
}

# CKEditor
CKEDITOR_UPLOAD_PATH = 'article/'
CKEDITOR_IMAGE_BACKEND = 'pillow'
CKEDITOR_FILENAME_GENERATOR = "aioa.my.ckeditor_media_path"
CKEDITOR_ALLOW_NONIMAGE_FILES = False
CKEDITOR_RESTRICT_BY_DATE = False
CKEDITOR_BROWSE_SHOW_DIRS = False
CKEDITOR_CONFIGS = {
    'default': {
        'language': 'zh-cn',
        'toolbar': 'full',
        'width': '100%',
        'tabSpaces': 4,
        'allowedContent': True,
        'filebrowserBrowseUrl': None,
        'extraPlugins': ','.join([
            'autogrow',
            'elementspath',
            'codesnippet',
            'lineheight'
        ]),
        'line_height': '1.3em;1.5em;2.0em;2.5em;3.0em;3.5em;4.0em',
    }
}


#####################
# Custom parameters #
#####################


class Variable:
    url_prefix = '/api'
    url_whitelist = {'', '/', '{}/base/login'.format(url_prefix)}
    url_blacklist = {}

    sep_ip = ','
    sep_menu_path = '/'
    sep_menu_relation_url = ','

    link_url = ';'
    link_name = ':::'
    link_node = '.'
    link_list = ' , '
    link_cascade = ' / '


v = Variable()


class Status:
    error = -1  # Error
    nl = 0  # No Login
    ok = 1  # OK
    na = 2  # No Authority


s = Status()

# Variable prefix for data type
s_: str
b_: bool

i_: int
f_: float
c_: complex

bs_: bytes
t_: tuple

vs_: set
vd_: dict
vl_: list

# Response template
context = {
    'status': s.ok,
    'message?': None,
    'data?': None,
}

print('DEBUG is {}'.format(DEBUG))
