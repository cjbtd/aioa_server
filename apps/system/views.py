from django.db import connections
from django.http import JsonResponse
from aioa.cache import KEY_HB, Cache, client
from aioa.security import encrypt
from aioa.settings import s
from aioa.utils import merge_dict
from aioa.sql import escape, sql_wrap, sql_eq, sql_like, sql_or, sql_and, sql_all_modules, sql_get_modules, \
    sql_search_role, sql_get_user_info
from apps.base.config import SystemConfig
from apps.base.models import ct, Config, Role, RolePerm, UserPerm
from apps.chat.views import push_msg


def perms(request):
    context = {
        'status': s.ok
    }

    is_add = request.GET.get('isAdd') == 'true'
    is_get = request.GET.get('isGet') == 'true'

    is_save_perm = request.GET.get('isSavePerm') == 'true'
    is_save_conf = request.GET.get('isSaveConf') == 'true'

    name_r = request.GET.get('nameR')
    name_p = request.GET.get('nameP')
    name_u = request.GET.get('nameU')

    id_r = request.GET.get('idR')
    id_p = request.GET.get('idP')

    id_ms = [int(idx) for idx in request.POST.getlist('idMs')]

    conf = request.POST.get('conf')

    if is_get:
        res = []
        if id_r:
            res = RolePerm.objects.values_list('module_id', 'perm_config_id').filter(role_id=id_r, enable=True)

        if name_u:
            res = UserPerm.objects.values_list('module_id', 'perm_config_id').filter(user=name_u, enable=True)

        context['data'] = encrypt({key: val for key, val in res})
        return JsonResponse(context)

    if is_add:
        if name_r:
            Role.objects.create(name=name_r)

        if name_p:
            Config.objects.create(name=name_p, type=ct.perm_type)

        if name_u and id_ms:
            UserPerm.objects.update_or_create(defaults={'enable': True}, user=name_u, module_id=id_ms[0])

    if is_save_perm and id_p and id_ms and (id_r or name_u):
        update_kwargs = {}
        filter_kwargs = {'module_id__in': id_ms}

        if id_p == '0':
            update_kwargs['enable'] = False
        else:
            update_kwargs['enable'] = True
            update_kwargs['perm_config_id'] = id_p

        if id_r:
            filter_kwargs['role_id'] = id_r
            obj = RolePerm
        else:
            filter_kwargs['user'] = name_u
            obj = UserPerm

        obj.objects.filter(**filter_kwargs).update(**update_kwargs)
        old_id_ms = obj.objects.values_list('module_id', flat=True).filter(**filter_kwargs)
        new_id_ms = set(id_ms).difference(set(old_id_ms))
        if new_id_ms:
            bulk_list = []
            if id_r:
                for idx in new_id_ms:
                    bulk_list.append(RolePerm(role_id=id_r, module_id=idx, **update_kwargs))
            else:
                for idx in new_id_ms:
                    bulk_list.append(UserPerm(user=name_u, module_id=idx, **update_kwargs))
            obj.objects.bulk_create(bulk_list)

        sc = SystemConfig()
        sc.refresh('Perm')
        context['message'] = '_T0016\f{}\v{}'.format(len(old_id_ms), len(new_id_ms))

    if is_save_conf and id_p and conf:
        if int(id_p) <= 20:  # id < 10 means base conf, change not allowed
            context['message'] = '_T0017'
            return JsonResponse(context)

        Config.objects.filter(pk=id_p).update(conf=conf)
        sc = SystemConfig()
        sc.refresh('Config', Config.objects.filter(pk=id_p))
        context['message'] = '_T0015'

    roles = Role.objects.filter(enable=True).order_by('-is_post', 'name').values('id', 'name')
    users = UserPerm.objects.filter(enable=True).order_by('user').values('user').distinct()
    configs = Config.objects.values('id', 'name', 'conf').filter(type=ct.perm_type)

    with connections['default'].cursor() as curs:
        curs.execute(sql_all_modules)
        modules = curs.fetchall()

    context['data'] = encrypt(
        {
            'names': list(roles) + list(users),
            'configs': list(configs),
            'modules': modules,
        }
    )
    return JsonResponse(context)


def permsquery(request):
    context = {
        'status': s.ok,
    }

    ids = request.GET.getlist('ids[]')
    user = request.GET.get('user')
    name = request.GET.get('name')

    if ids:
        sc = SystemConfig()

        if len(ids) == 4:
            conf = sc.load_conf(*ids)
        else:
            conf = {}
            for idx in ids:
                merge_dict(conf, sc.loads(idx))

        context['data'] = encrypt(conf)

    if user or name:
        conditions = []
        if user:
            conditions.append(sql_eq.format(sql_wrap.format('user'), escape(user)))
        else:
            pass

        if name:
            name = escape(name, True)
            conditions.append(
                '({})'.format(
                    sql_or.join(
                        [
                            sql_like.format(sql_wrap.format('name'), '', name),
                            sql_like.format(sql_wrap.format('label'), '', name)
                        ]
                    )
                )
            )

            with connections['default'].cursor() as curs:
                curs.execute(sql_search_role.format(name))
                context['message'] = ';'.join([row[0] for row in curs.fetchall()])
        else:
            pass

        with connections['default'].cursor() as curs:
            curs.execute(sql_get_modules.format(sql_and.join(conditions)))
            context['data'] = encrypt(curs.fetchall())
    return JsonResponse(context)


def onliners(request):
    context = {
        'status': s.ok
    }

    if request.method == 'POST':
        msg = request.POST.get('msg')
        users = request.POST.getlist('users')

        username = request.user.username
        if username == 'admin' and msg == 'clean':
            for user in users:
                client.delete(user)
        else:
            push_msg(users, {'msg': '[{}]{}'.format(username, msg)})

        context['message'] = '_T0018'
        return JsonResponse(context)

    with connections['default'].cursor() as curs:
        curs.execute(sql_get_user_info)
        userinfos = curs.fetchall()

    context['data'] = encrypt([
        {
            'username': username,
            'full_name': full_name,
            'is_online': Cache(KEY_HB, username).get() == 0,
            'un_pushed': client.llen(username),
            'info': {
                '称谓': abbr_name,
                '职位': position,
                '主管': leaders,
                '邮箱': email,
                '座机': tel,
                '手机': mp,
                '当前IP': ip,
                '绑定IP': ips,
                '最后登录日期': last_login,
                '账号创建日期': date_joined,
                '权限': roles,
                '备注': remark,
                '浏览器': agent,
            },
            'pk': pk,
            'gid': gid,
        } for (
            username,
            last_login,
            agent,
            ips,
            date_joined,
            full_name,
            position,
            leaders,
            abbr_name,
            email,
            tel,
            mp,
            roles,
            remark,
            ip,
            pk,
            gid) in userinfos
    ])
    return JsonResponse(context)
