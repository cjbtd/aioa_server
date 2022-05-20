from django.urls import re_path
from . import views

urlpatterns = [
    re_path('^$', views.home),
    re_path('^remote$', views.remote),
    re_path('^touch$', views.touch),
    re_path('^upload$', views.upload),
    re_path('^printed$', views.printed),
    re_path('^menu$', views.menu),
    re_path('^calendar$', views.calendar),
    re_path('^userroles$', views.user_roles),
    re_path('^userconfs$', views.user_confs),
    re_path('^login$', views.log_in),
    re_path('^logout$', views.log_out),
]
