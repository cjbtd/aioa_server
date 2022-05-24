from django.contrib.auth import authenticate, login, logout
from django.db import connections
from django.http import JsonResponse
from django.middleware.csrf import get_token
from django.shortcuts import render
from aioa.cache import Cache, KEY_UNAME, KEY_ROLES, KEY_MENUS, KEY_METAS, KEY_PRINTED
from aioa.security import encrypt
from aioa.settings import v, s, FILES_ROOT
from aioa.sql import escape, vals_to_strs, sql_get_calendar_events, sql_update_user_info
from aioa.utils import logger, zip_data, to_int, get_ip, get_random_str
from apps.base.config import SystemConfig, is_exist_file
from apps.base.models import ct, UserRole, UserConf, DataBook, DataDict
from apps.chat.views import push_mail
from datetime import datetime, timedelta
from pathlib import Path
import hashlib


def home(request):
    """
    Website Entry

    """
    return render(request, 'index.html')


def menu(request):
    username = request.user.username
    context = {'status': s.ok}

    sc = SystemConfig(username)
    context['data'] = encrypt({'MENUS': sc.get(KEY_MENUS), 'METAS': sc.get(KEY_METAS)})
    return JsonResponse(context)


def calendar(request):
    username = request.user.username
    s_day = request.GET.get('day')
    context = {'status': s.ok}

    fmt = '%Y-%m-%d'

    try:
        day = datetime.strptime(s_day, fmt)
    except Exception as e:
        logger.warning('date format error | {} | {} | {}'.format(username, s_day, e.__str__()))
        day = (datetime.today().replace(day=1) + timedelta(days=-6)).strftime(fmt)

    sql = sql_get_calendar_events.format(escape(day), escape(username))

    logger.debug(sql)

    with connections['default'].cursor() as curs:
        curs.execute(sql)
        data = curs.fetchall()

    context['data'] = encrypt(data)
    return JsonResponse(context)


def user_roles(request):
    context = {
        'status': s.ok,
        'data': encrypt(get_roles(request.user.username))
    }
    return JsonResponse(context)


def user_confs(request):
    username = request.user.username
    context = {'status': s.ok}

    userconf = request.POST.get('userconf')
    if userconf:
        UserConf.objects.update_or_create(defaults={'conf': userconf}, user=username)
        context['message'] = '_T0015'
    else:
        confs = UserConf.objects.filter(user__in=[username, 'system']).order_by('id').values_list('conf', flat=True)
        sc = SystemConfig(username)

        context['data'] = encrypt({
            'confs': list(confs),
            'message': sc.get_obj('message'),
            'textmap': sc.get_obj('textmap'),
        })
    return JsonResponse(context)


def log_in(request):
    # Here, you can restrict the device login according to the agent
    agent = request.META.get('HTTP_USER_AGENT')
    context = {'status': s.ok}

    if request.method == 'POST':
        username = request.POST.get('username', '')
        password = request.POST.get('password', '')

        user = authenticate(username=username, password=password)

        if not user:
            context['status'] = s.error
            context['message'] = '_T0001'
            return JsonResponse(context)

        ip = get_ip(request)  # Current IP
        ips = user.email  # Bound IPs

        if ips:
            if ips != '*' and ip not in ips.split(v.sep_ip):
                context['message'] = '_T0002\f{}\v{}'.format(ip, username)
                return JsonResponse(context)

            logger.info('username: {} ip: {} bind ip: {}'.format(username, ip, ips))
        else:
            logger.info('username：{} first bind ip：{}'.format(username, ip))

        login(request, user)

        session_key = request.session.session_key

        Cache(KEY_UNAME, username).set(session_key)

        # Some agent is too long, must be limited to 150 chars
        if agent and len(agent) > 150:
            agent = agent[:45] + ' ... ' + agent[-90:]
        else:
            pass

        sql = sql_update_user_info.format(escape(username), escape(agent), escape(ips), escape(ip))

        logger.info(sql)

        with connections['default'].cursor() as curs:
            curs.execute(sql)

        push_mail(username)

        response = JsonResponse(context)
        response.set_cookie('admin', request.user.is_staff)
        response.set_cookie('username', username)
        return response
    get_token(request)
    return JsonResponse(context)


def log_out(request):
    context = {
        'status': s.nl,
    }
    logout(request)
    return JsonResponse(context)


def remote(request):
    username = request.user.username
    context = {'status': s.ok, }

    sc = SystemConfig()
    conf, _type = sc.get_config(to_int(request.GET.get('idx')))

    val = None
    if _type == ct.sql_type:
        if conf.startswith('-- remote get labels by values'):
            values = request.GET.getlist('value[]', request.GET.getlist('value', []))
            val = vals_to_strs(values, ['', 'NULL', None]) or None
        else:
            pass

        if conf.startswith('-- remote get values by label'):
            label = request.GET.get('label')
            val = label and escape(label, True)
        else:
            pass
    else:
        pass

    if val:
        sql = conf.format(val, escape(username), escape(request.GET.get('ref')))

        logger.info(sql)

        with connections['default'].cursor() as curs:
            curs.execute(sql)
            data = curs.fetchall()

        context['data'] = encrypt(zip_data(['value', 'label'], data))
    else:
        context['status'] = s.na
    return JsonResponse(context)


def touch(request):
    s_md5 = request.GET.get('md5')
    context = {'status': s.ok, 'data': encrypt(is_exist_file(s_md5))}
    return JsonResponse(context)


def upload(request):
    files = []
    attachments = request.FILES.getlist('attachments')
    for attachment in attachments:
        md = hashlib.md5()

        tmp_name = FILES_ROOT / get_random_str()
        with open(tmp_name, 'wb+') as f:
            for data in attachment.chunks(chunk_size=4096):
                f.write(data)
                md.update(data)

        md5 = md.hexdigest()
        if is_exist_file(md5):
            Path(tmp_name).unlink(True)
        else:
            Path(tmp_name).rename(FILES_ROOT / md5)

        files.append({'name': attachment.name, 'md5': md5})

    context = {'status': s.ok, 'data': encrypt(files)}
    return JsonResponse(context)


def printed(request):
    cache = Cache(KEY_PRINTED)
    record = cache.get(set())

    md5s = request.POST.getlist('md5s')
    save = request.POST.get('save', 'false') == 'true'

    unrecord = [index for index, md5 in enumerate(md5s) if md5 in record]

    if save and unrecord:
        cache.set(record | set(md5s))
    else:
        pass

    context = {'status': s.ok, 'data': None if save else encrypt(unrecord)}
    return JsonResponse(context)


def get_roles(username: str) -> list:
    """
    Get user role list

    :param username: Str, UserName
    :return: List
    """
    cache = Cache(KEY_ROLES, username)

    data = cache.get()
    if data is None:
        data = []
        for ur in UserRole.objects.filter(user=username, enable=True):
            if ur.role.is_post:
                data.append({'id': ur.role_id, 'name': ur.role.name})
            else:
                pass
        cache.set(data)
    else:
        pass
    return data


def get_data_book(table: str) -> str:
    """
    Get table book by table name

    :param table: Str, The table name
    :return: Str
    """
    remarks = DataBook.objects.filter(table=table, enable=True).values_list('remark', flat=True)
    return remarks[0] if remarks else None


def get_data_dict(keys: list) -> list:
    """
    Get table dict by table column's alias list

    :param keys: List, The table column's alias list
    :return: List
    """
    dicts = DataDict.objects.filter(alias__in=keys, status='1').values_list('alias', 'remark')
    return list(dicts) or None
