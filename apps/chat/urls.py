from django.urls import re_path
from .views import heartbeat, user_name, user_mail, send_mail, download, user_info

urlpatterns = [
    re_path('^heartbeat$', heartbeat),
    re_path('^username$', user_name),
    re_path('^usermail$', user_mail),
    re_path('^sendmail$', send_mail),
    re_path('^download$', download),
    re_path('^userinfo$', user_info),
]
