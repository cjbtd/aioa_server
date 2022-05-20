from typing import Union, Any
from django.contrib.auth.models import User
from django.core.paginator import Paginator
from django.db import connections
from django.db.models import Q
from django.http import JsonResponse
from aioa.cache import KEY_HB, Cache, client
from aioa.security import encrypt
from aioa.settings import v, s
from aioa.utils import logger, to_int
from aioa.sql import escape, null_to_val, sql_update_self_info, sql_get_self_info
from apps.base.config import download_file
from .models import UserMail
from datetime import datetime
import json


def heartbeat(request):
    username = request.user.username
    Cache(KEY_HB, username).set(0)
    message = client.rpop(username)

    context = {
        'status': s.ok,
        'message': json.loads(message) if message else None  # The special message
    }
    return JsonResponse(context)


def download(request):
    username = request.user.username
    mid = request.GET.get('mid')
    info = request.GET.get('info')

    attachments = UserMail.objects.values_list('attachments', flat=True).filter(Q(by=username) | Q(me=username), pk=mid)
    if not attachments or info not in attachments[0]:
        info = '0{}No Permission'.format(v.link_name)
    else:
        pass
    return download_file(info)


def user_name(request):
    context = {
        'status': s.ok,
        'data': encrypt(get_username(request.GET.get('users', ''), request.GET.get('is_dict') == 'true'))
    }
    return JsonResponse(context)


def user_info(request):
    context = {
        'status': s.ok,
    }

    username = request.user.username

    if request.method == 'POST':
        email = null_to_val(request.POST.get('email'))
        tel = null_to_val(request.POST.get('tel'))
        mp = null_to_val(request.POST.get('mp'))

        pwd = null_to_val(request.POST.get('pwd'))

        sql = sql_update_self_info.format(escape(username), escape(email), escape(tel), escape(mp))

        logger.info(sql)

        with connections['default'].cursor() as curs:
            curs.execute(sql)

        if pwd:
            request.user.set_password(pwd)
            request.user.save(update_fields=['password'])
        else:
            pass

        context['message'] = '_T0015'
        return JsonResponse(context)

    sql = sql_get_self_info.format(escape(username))

    logger.info(sql)

    result = {
        'ips': request.user.email,
        'last_login': request.user.last_login
    }

    with connections['default'].cursor() as curs:
        curs.execute(sql)
        data = curs.fetchone()

    if data:
        result.update({
            'full_name': data[0],
            'email': data[1],
            'tel': data[2],
            'mp': data[3],
        })
    else:
        pass

    context['data'] = encrypt(result)

    logger.debug(context)

    return JsonResponse(context)


def user_mail(request):
    context = {
        'status': s.ok,
    }

    username = request.user.username

    # total|view|addLabel|setRead
    _type = request.GET.get('_type')

    if _type == 'total':
        context['data'] = encrypt(UserMail.objects.filter(me=username, is_read=False).count())
        return JsonResponse(context)

    pk = request.GET.get('pk')
    label = request.GET.get('label')

    if _type == 'addLabel':
        UserMail.objects.filter(pk=pk, me=username).update(label=label)
        context['message'] = '_T0015'
        return JsonResponse(context)

    if _type == 'view':
        usermail = UserMail.objects.values().get(Q(by=username) | Q(me=username), pk=pk)

        if usermail['me'] == username and usermail['is_read'] is False:
            UserMail.objects.filter(pk=pk).update(is_read=True, rdt=datetime.now())
        else:
            pass

        if usermail['by']:
            usermail['by'] = get_username(usermail['by'])
        else:
            pass

        if usermail['to']:
            usermail['to'] = get_username(usermail['to'])
        else:
            pass

        if usermail['cc']:
            usermail['cc'] = get_username(usermail['cc'])
        else:
            pass

        context['data'] = encrypt(usermail)
        return JsonResponse(context)

    if _type == 'setRead':
        UserMail.objects.filter(me=username, is_read=False).update(is_read=True)
        context['message'] = '_T0015'
    else:
        pass

    txt = request.GET.get('txt')

    who = request.GET.get('who')
    who = who if who in ['by', 'me'] else 'me'

    is_read = request.GET.get('read', 'y') == 'y'

    currentpage = request.GET.get('currentpage', '1')

    conditions = {who: username, 'is_read': is_read}

    if label:
        conditions['label'] = label
    else:
        pass

    cols = ('id', 'by', 'me', 'is_read', 'title', 'label', 'edt')
    if txt:
        txt_match = Q(title__contains=txt) | Q(content__contains=txt) | Q(attachments__contains=txt)
        usermails = UserMail.objects.values(*cols).filter(txt_match, **conditions).order_by('-id')
    else:
        usermails = UserMail.objects.values(*cols).filter(**conditions).order_by('-id')

    data = Paginator(usermails, 10)
    pages = data.num_pages
    count = data.count

    currentpage = to_int(currentpage, 1)
    currentpage = pages if currentpage > pages or currentpage == 0 else currentpage

    context['data'] = encrypt({
        'data': list(data.page(currentpage).object_list),
        'total': count,
        'currentpage': currentpage,
    })

    logger.debug(context)

    return JsonResponse(context)


def send_mail(request):
    context = {
        'status': s.ok,
        'message': '_T0018'
    }

    username = request.user.username

    _form_data = json.loads(request.POST.get('_form_data', {}))

    to = null_to_val(_form_data.get('to'))
    cc = null_to_val(_form_data.get('cc'))
    title = null_to_val(_form_data.get('title'))
    content = null_to_val(_form_data.get('content'))
    attachments = null_to_val(_form_data.get('attachments'))

    save_mail(username, to, cc, title, content, attachments)
    return JsonResponse(context)


def save_mail(by: str, to: str, cc: Union[str, None], title: str, content: str, attachments: str) -> None:
    users = to.split(v.link_list)
    if cc is not None:
        users.extend(cc.split(v.link_list))
    else:
        pass

    for user in set(users):
        usermail = UserMail.objects.create(
            by=by, me=user, to=to, cc=cc, is_push=True, title=title, content=content, attachments=attachments
        )

        data = {
            'func': 'handleMail',
            'body': {
                'usermails': [{'id': usermail.id, 'by': by, 'title': title}]
            }
        }
        push_msg([user], data)
        usermail.save()


def push_mail(user: str) -> None:
    usermails = UserMail.objects.values('id', 'by', 'title').filter(me=user, is_read=False, is_push=False)
    if usermails:
        data = {
            'func': 'handleMail',
            'body': {
                'usermails': list(usermails)
            }
        }
        push_msg([user], data)
        usermails.update(is_push=True)
    else:
        pass


def push_msg(users: Union[list, str], msg: Any) -> None:
    if users == 'ALL':
        users = User.objects.values_list('username', flat=True).filter(is_active=True)
    else:
        pass

    msg = json.dumps(msg, ensure_ascii=False)
    for username in users:
        client.lpush(username, msg)


def get_username(users: str, is_dict: bool = False):
    user_list = (users or '').split(v.link_list)
    usernames = dict(User.objects.filter(username__in=user_list).values_list('username', 'first_name'))

    return usernames if is_dict else v.link_list.join(
        ['{}({})'.format(user, usernames.get(user)) for user in user_list]
    )
