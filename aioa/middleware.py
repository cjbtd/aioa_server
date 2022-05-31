from django.contrib.auth import logout
from django.http import JsonResponse
from django.utils.deprecation import MiddlewareMixin
from .cache import Cache, KEY_PATHS, KEY_UNAME
from .settings import v, s
from .utils import logger, get_ip
from apps.base.config import SystemConfig


class ControlMiddleware(MiddlewareMixin):
    @staticmethod
    def process_request(request):
        ip = get_ip(request)
        path = request.path_info
        username = request.user.username

        logger.info('{} {} {} {} {}'.format(username, ip, path, request.GET, request.POST))

        # Account exclusivity
        if not (Cache(KEY_UNAME, username).get() == request.session.session_key):
            logout(request)
        else:
            pass

        # Forbidden access
        if path in v.url_blacklist:
            return JsonResponse({'status': s.error})

        # Login required
        if request.user.is_authenticated:
            # Authentication
            if path.startswith(v.url_prefix) and path[len(v.url_prefix):] not in SystemConfig(username).get(KEY_PATHS):
                return JsonResponse({'status': s.na})
        else:
            if path not in v.url_whitelist:
                return JsonResponse({'status': s.nl})

    @staticmethod
    def process_exception(request, exception):
        ip = get_ip(request)
        path = request.path_info
        username = request.user.username

        message = exception.__str__()
        logger.error('{} {} {} {}'.format(username, ip, path, message))

        return JsonResponse({'status': s.error, 'message': message})
