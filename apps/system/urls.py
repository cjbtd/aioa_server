from django.urls import re_path
from .views import perms, permsquery, onliners

urlpatterns = [
    re_path('^perms$', perms),
    re_path('^permsquery$', permsquery),
    re_path('^onliners$', onliners),
]
