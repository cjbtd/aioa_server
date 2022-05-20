from django.contrib import admin
from .models import *
from .config import SystemConfig
import time

admin.site.site_title = '后台管理'
admin.site.site_header = '后台管理系统'
admin.site.index_title = '应用管理'
admin.site.disable_action('delete_selected')

sc = SystemConfig()


@admin.register(Config)
class ConfigAdmin(admin.ModelAdmin):
    list_display_links = ('id',)
    list_display = ('id', 'name', 'conf', 'type', 'remark', 'edt', 'udt')
    list_editable = ('name', 'conf', 'type', 'remark')
    list_filter = ('type',)
    search_fields = ('name', 'conf', 'remark')
    list_per_page = 5
    actions = ['refresh', 'zip', 'format']

    def refresh(self, request, queryset):
        self.message_user(request, '刷新成功，{}条受影响'.format(sc.refresh('Config', queryset)))

    def zip(self, request, queryset):
        total = 0
        for config in queryset:
            if config.type in JSON_TYPES:
                total += 1
                config.conf = sc.format_json(config.conf)
                config.save()
        self.message_user(request, '压缩成功，共{}条'.format(total))

    def format(self, request, queryset):
        total = 0
        for config in queryset:
            if config.type in JSON_TYPES:
                total += 1
                config.conf = sc.format_json(config.conf, 2).strip()
                config.save()
        self.message_user(request, '格式化成功，共{}条'.format(total))

    refresh.short_description = '刷新'
    zip.short_description = '压缩'
    format.short_description = '格式化'


@admin.register(Menu)
class MenuAdmin(admin.ModelAdmin):
    list_display_links = ('id',)
    list_display = ('id', 'path', 'name', 'sort', 'relations', 'enable')
    list_editable = ('path', 'name', 'sort', 'relations', 'enable')
    list_filter = ('enable',)
    search_fields = ('path', 'name', 'relations', 'meta')
    list_per_page = 10
    actions = ['refresh', 'create_module']

    def refresh(self, request, queryset):
        self.message_user(request, '刷新成功，{}条受影响'.format(sc.refresh('Menu', queryset)))

    def create_module(self, request, queryset):
        total = 0
        for menu in queryset:
            if Module.objects.filter(menu=menu).count() == 0:
                Module.objects.create(menu=menu, label=menu.name.split('/')[-1])
                total += 1

        self.message_user(request, '执行成功，生成 {} 项'.format(total))

    refresh.short_description = '刷新'
    create_module.short_description = '生成默认模块'


@admin.register(Module)
class ModuleAdmin(admin.ModelAdmin):
    list_display_links = ('id',)
    list_display = ('id', 'menu', 'label', 'value', 'sort', 'base_config', 'over_config', 'spec_config', 'enable')
    list_editable = ('menu', 'label', 'value', 'sort', 'base_config', 'over_config', 'spec_config', 'enable')
    list_filter = ('enable',)
    search_fields = ('menu__name', 'label', 'base_config__name', 'over_config__name', 'spec_config__name')
    list_per_page = 10
    actions = ['refresh']

    def refresh(self, request, queryset):
        self.message_user(request, '刷新成功，{}条受影响'.format(sc.refresh('Module', queryset)))

    refresh.short_description = '刷新'

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name in ('base_config', 'over_config', 'spec_config'):
            kwargs['queryset'] = Config.objects.filter(type=ct.conf_type)
        return super(ModuleAdmin, self).formfield_for_foreignkey(db_field, request, **kwargs)


@admin.register(Role)
class RoleAdmin(admin.ModelAdmin):
    list_display_links = ('id',)
    list_display = ('id', 'name', 'is_post', 'enable', 'edt', 'udt')
    list_editable = ('name', 'is_post', 'enable')
    list_filter = ('is_post', 'enable')
    search_fields = ('name',)
    list_per_page = 10
    actions = ['refresh', 'copy_role']

    def refresh(self, request, queryset):
        self.message_user(request, '刷新成功，{}条受影响'.format(sc.refresh('Role', queryset)))

    def copy_role(self, request, queryset):
        msg = []
        for role in queryset:
            new_name = role.name + time.strftime('_%Y%m%d%H%M%S')
            new_role = Role.objects.create(name=new_name)
            roleperms = RolePerm.objects.filter(role=role)
            for roleperm in roleperms:
                RolePerm.objects.create(role=new_role, module=roleperm.module, perm_config=roleperm.perm_config)

            msg.append('复制角色【{}】成功，新角色名是【{}】，复制权限 {} 条'.format(role, new_name, len(roleperms)))
        self.message_user(request, '; '.join(msg))

    refresh.short_description = '刷新'
    copy_role.short_description = '复制角色'


@admin.register(RolePerm)
class RolePermAdmin(admin.ModelAdmin):
    list_display_links = ('id',)
    list_display = ('id', 'role', 'module', 'perm_config', 'enable', 'edt', 'udt')
    list_editable = ('role', 'module', 'perm_config', 'enable')
    list_filter = ('enable',)
    search_fields = ('role__name', 'module__label', 'perm_config__name')
    list_per_page = 10
    actions = ['refresh']

    def refresh(self, request, queryset):
        self.message_user(request, '刷新成功，{}条受影响'.format(sc.refresh('RolePerm', queryset)))

    refresh.short_description = '刷新'

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name == 'perm_config':
            kwargs['queryset'] = Config.objects.filter(type=ct.perm_type)
        return super(RolePermAdmin, self).formfield_for_foreignkey(db_field, request, **kwargs)


@admin.register(UserRole)
class UserRoleAdmin(admin.ModelAdmin):
    list_display_links = ('id',)
    list_display = ('id', 'user', 'role', 'enable', 'edt', 'udt')
    list_editable = ('user', 'role', 'enable')
    list_filter = ('enable',)
    search_fields = ('user', 'role__name')
    list_per_page = 10
    actions = ['refresh']

    def refresh(self, request, queryset):
        self.message_user(request, '刷新成功，{}条受影响'.format(sc.refresh('UserRole', queryset)))

    refresh.short_description = '刷新'


@admin.register(UserPerm)
class UserPermAdmin(admin.ModelAdmin):
    list_display_links = ('id',)
    list_display = ('id', 'user', 'module', 'perm_config', 'enable', 'edt', 'udt')
    list_editable = ('user', 'module', 'perm_config', 'enable')
    list_filter = ('enable',)
    search_fields = ('user', 'module__label', 'perm_config__name')
    list_per_page = 10
    actions = ['refresh']

    def refresh(self, request, queryset):
        self.message_user(request, '刷新成功，{}条受影响'.format(sc.refresh('UserPerm', queryset)))

    refresh.short_description = '刷新'

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name == 'perm_config':
            kwargs['queryset'] = Config.objects.filter(type=ct.perm_type)
        return super(UserPermAdmin, self).formfield_for_foreignkey(db_field, request, **kwargs)


@admin.register(UserConf)
class UserConfAdmin(admin.ModelAdmin):
    list_display_links = ('id',)
    list_display = ('id', 'user', 'conf', 'remark', 'edt', 'udt')
    list_editable = ('user', 'conf', 'remark')
    search_fields = ('user', 'conf', 'remark')
    list_per_page = 5


@admin.register(DataBook)
class DataBookAdmin(admin.ModelAdmin):
    list_display_links = ('id',)
    list_display = ('id', 'db', 'table', 'label', 'enable', 'edt', 'udt')
    list_editable = ('db', 'table', 'label', 'enable')
    list_filter = ('db', 'enable')
    search_fields = ('table', 'label', 'remark')
    list_per_page = 10


@admin.register(DataDict)
class DataDictAdmin(admin.ModelAdmin):
    list_display_links = ('id',)
    list_display = ('id', 'table', 'column', 'alias', 'label', 'status', 'edt', 'udt')
    list_editable = ('table', 'column', 'alias', 'label', 'status')
    list_filter = ('status',)
    search_fields = ('column', 'alias', 'label')
    list_per_page = 10
