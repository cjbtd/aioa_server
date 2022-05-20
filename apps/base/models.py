from django.db import models
from ckeditor_uploader.fields import RichTextUploadingField


class ConfigType:
    conf_type = '1'  # e.g. {}
    perm_type = '2'  # e.g. {}
    flow_type = '3'  # e.g. {}
    json_type = '4'  # e.g. {} or []
    list_type = '5'  # e.g. []
    dict_type = '6'  # e.g. {}
    text_type = '7'  # e.g. aioa is the best
    html_type = '8'  # e.g. <h1 style="color: red;">aioa is the best</h1>
    sql_type = '9'  # e.g. SELECT username FROM auth_user WHERE is_active = 1


ct = ConfigType()

# These types are standard JSON formatted text
JSON_TYPES = {ct.conf_type, ct.perm_type, ct.flow_type, ct.json_type, ct.list_type, ct.dict_type}

# These types are JSON items after removing the first and last character
# e.g.  JSON_TYPE      : { "#1#": "#0#", "enums": [ 1, 2, 4, "#2#", 9] }
#       LIST_TYPE(id:2): [ 5, 6, 7, 8 ]
#       DICT_TYPE(id:1): { "a": "b" }
# ("#id#") will reference the config id and replace it
# (: "#0#") is a placeholder, which will be automatically removed during parsing
# parse result: { "a": "b", "enums": [ 1, 2, 4, 5, 6, 7, 8, 9] }
JSON_ITEM_TYPES = {ct.list_type, ct.dict_type}

# These types are plain text
JSON_TEXT_TYPES = {ct.text_type, ct.html_type, ct.sql_type}

# Can be referenced by other config use "#id#"
REFERABLE_TYPES = {ct.conf_type, ct.json_type, ct.list_type, ct.dict_type}

DEFAULT_CONF_CONFIG_ID = 1
DEFAULT_PERM_CONFIG_ID = 2
DEFAULT_FLOW_CONFIG_ID = 3
DEFAULT_MAPS_CONFIG_ID = 4

CONFIG_TYPES = [
    (ct.conf_type, '配置'),
    (ct.perm_type, '权限'),
    (ct.flow_type, '流程'),
    (ct.json_type, '标准'),
    (ct.list_type, '列表'),
    (ct.dict_type, '字典'),
    (ct.text_type, '文本'),
    (ct.html_type, '网页'),
    (ct.sql_type, '语句'),
]


class Config(models.Model):
    name = models.CharField(max_length=64, null=False, blank=False, verbose_name=u'名称')
    conf = models.TextField(default='{}', null=False, blank=False, verbose_name=u'配置')
    type = models.CharField(default=ct.conf_type, max_length=1, null=False, blank=False, verbose_name=u'类型',
                            choices=CONFIG_TYPES)
    remark = models.TextField(null=True, blank=True, verbose_name=u'备注')
    edt = models.DateTimeField(auto_now_add=True, verbose_name=u'录入时间')
    udt = models.DateTimeField(auto_now=True, verbose_name=u'更新时间')

    def __str__(self):
        return self.name

    class Meta:
        verbose_name = '配置'
        verbose_name_plural = '00.配置'
        unique_together = ('name',)


class Menu(models.Model):
    path = models.CharField(max_length=64, null=False, blank=False, verbose_name=u'路由')
    name = models.CharField(max_length=128, null=False, blank=False, verbose_name=u'菜单', help_text=u'层级分割符：/')
    sort = models.IntegerField(default=1000, null=False, blank=False, verbose_name=u'排序', help_text=u'数字小的在前面')
    meta = models.TextField(default='{}', null=False, blank=False, verbose_name=u'属性')
    relations = models.CharField(max_length=1024, null=True, blank=True, verbose_name=u'关联路由', help_text=u'分割符：,')
    enable = models.BooleanField(default=True, null=False, blank=False, verbose_name=u'启用')
    edt = models.DateTimeField(auto_now_add=True, verbose_name=u'录入时间')
    udt = models.DateTimeField(auto_now=True, verbose_name=u'更新时间')

    def __str__(self):
        return self.name

    class Meta:
        ordering = ['sort', 'id']
        verbose_name = '菜单'
        verbose_name_plural = '01.菜单'
        unique_together = ('path',)


class Module(models.Model):
    menu = models.ForeignKey(Menu, on_delete=models.CASCADE, to_field='id', verbose_name='菜单')
    label = models.CharField(max_length=32, null=False, blank=False, verbose_name=u'模块名', help_text=u'菜单下必须唯一')
    value = models.IntegerField(default=0, null=False, blank=False, verbose_name=u'模块值', help_text=u'菜单下必须唯一')
    sort = models.IntegerField(default=100, null=False, blank=False, verbose_name=u'排序', help_text=u'数字小的在前面')
    base_config = models.ForeignKey(Config, on_delete=models.CASCADE, to_field='id', default=DEFAULT_CONF_CONFIG_ID,
                                    related_name='base_config_id', verbose_name='基础配置')
    over_config = models.ForeignKey(Config, on_delete=models.CASCADE, to_field='id', default=DEFAULT_CONF_CONFIG_ID,
                                    related_name='over_config_id', verbose_name='附加配置')
    spec_config = models.ForeignKey(Config, on_delete=models.CASCADE, to_field='id', default=DEFAULT_CONF_CONFIG_ID,
                                    related_name='spec_config_id', verbose_name='特殊配置')
    enable = models.BooleanField(default=True, null=False, blank=False, verbose_name=u'启用')
    edt = models.DateTimeField(auto_now_add=True, verbose_name=u'录入时间')
    udt = models.DateTimeField(auto_now=True, verbose_name=u'更新时间')

    def __str__(self):
        return '{} : {}'.format(self.menu, self.label)

    class Meta:
        verbose_name = '模块'
        verbose_name_plural = '02.模块'
        unique_together = ('menu', 'label', 'value')


class Role(models.Model):
    name = models.CharField(max_length=32, null=False, blank=False, verbose_name=u'角色')
    is_post = models.BooleanField(default=False, null=False, blank=False, verbose_name=u'岗位')
    enable = models.BooleanField(default=True, null=False, blank=False, verbose_name=u'启用')
    edt = models.DateTimeField(auto_now_add=True, verbose_name=u'录入时间')
    udt = models.DateTimeField(auto_now=True, verbose_name=u'更新时间')

    def __str__(self):
        return self.name

    class Meta:
        verbose_name = '角色'
        verbose_name_plural = '03.角色'
        unique_together = ('name',)


class RolePerm(models.Model):
    role = models.ForeignKey(Role, on_delete=models.CASCADE, to_field='id', verbose_name='角色')
    module = models.ForeignKey(Module, on_delete=models.CASCADE, to_field='id', verbose_name='模块')
    perm_config = models.ForeignKey(Config, on_delete=models.CASCADE, to_field='id', default=DEFAULT_PERM_CONFIG_ID,
                                    related_name='role_perm_config_id', verbose_name='权限配置')
    enable = models.BooleanField(default=True, null=False, blank=False, verbose_name=u'启用')
    edt = models.DateTimeField(auto_now_add=True, verbose_name=u'录入时间')
    udt = models.DateTimeField(auto_now=True, verbose_name=u'更新时间')

    def __str__(self):
        return '{} : {}'.format(self.role, self.module)

    class Meta:
        verbose_name = '角色权限'
        verbose_name_plural = '04.角色权限'
        unique_together = ('role', 'module')


class UserRole(models.Model):
    user = models.CharField(max_length=8, null=False, blank=False, verbose_name=u'账号')
    role = models.ForeignKey(Role, on_delete=models.CASCADE, to_field='id', verbose_name='角色')
    enable = models.BooleanField(default=True, null=False, blank=False, verbose_name=u'启用')
    edt = models.DateTimeField(auto_now_add=True, verbose_name=u'录入时间')
    udt = models.DateTimeField(auto_now=True, verbose_name=u'更新时间')

    def __str__(self):
        return '{} : {}'.format(self.user, self.role)

    class Meta:
        verbose_name = '账号角色'
        verbose_name_plural = '05.账号角色'
        unique_together = ('user', 'role')


class UserPerm(models.Model):
    user = models.CharField(max_length=8, null=False, blank=False, verbose_name=u'账号')
    module = models.ForeignKey(Module, on_delete=models.CASCADE, to_field='id', verbose_name='模块')
    perm_config = models.ForeignKey(Config, on_delete=models.CASCADE, to_field='id', default=DEFAULT_PERM_CONFIG_ID,
                                    related_name='user_perm_config_id', verbose_name='权限配置')
    remark = models.TextField(null=True, blank=True, verbose_name=u'备注')
    enable = models.BooleanField(default=True, null=False, blank=False, verbose_name=u'启用')
    edt = models.DateTimeField(auto_now_add=True, verbose_name=u'录入时间')
    udt = models.DateTimeField(auto_now=True, verbose_name=u'更新时间')

    def __str__(self):
        return '{} : {}'.format(self.user, self.module)

    class Meta:
        verbose_name = '账号权限'
        verbose_name_plural = '06.账号权限'
        unique_together = ('user', 'module')


class UserConf(models.Model):
    user = models.CharField(max_length=8, null=False, blank=False, verbose_name=u'账号')
    conf = models.TextField(default='{}', null=False, blank=False, verbose_name=u'配置')
    remark = models.TextField(null=True, blank=True, verbose_name=u'备注')
    edt = models.DateTimeField(auto_now_add=True, verbose_name=u'录入时间')
    udt = models.DateTimeField(auto_now=True, verbose_name=u'更新时间')

    def __str__(self):
        return self.user

    class Meta:
        verbose_name = '个人配置'
        verbose_name_plural = '07.个人配置'
        unique_together = ('user',)


class DataBook(models.Model):
    db = models.CharField(max_length=32, null=False, blank=False, verbose_name=u'数据库')
    table = models.CharField(max_length=128, null=False, blank=False, verbose_name=u'数据表')
    label = models.CharField(max_length=128, null=True, blank=True, verbose_name=u'标签')
    remark = RichTextUploadingField(null=True, blank=True, verbose_name=u'备注')
    enable = models.BooleanField(default=True, null=False, blank=False, verbose_name=u'启用')
    edt = models.DateTimeField(auto_now_add=True, verbose_name=u'录入时间')
    udt = models.DateTimeField(auto_now=True, verbose_name=u'更新时间')

    def __str__(self):
        return '{}.{}'.format(self.db, self.table)

    class Meta:
        verbose_name = '数据手册'
        verbose_name_plural = '08.数据手册'
        unique_together = ('db', 'table')


DATADICT_STATUS = (
    ('0', '未审核'),
    ('1', '已审核'),
    ('2', '不一致'),
    ('3', '已废弃'),
    ('4', '已删除'),
)


class DataDict(models.Model):
    table = models.ForeignKey(DataBook, on_delete=models.CASCADE, to_field='id', verbose_name=u'数据表')
    column = models.CharField(max_length=128, null=False, blank=False, verbose_name=u'字段')
    column_id = models.SmallIntegerField(null=False, blank=False, verbose_name=u'字段序号')
    column_type = models.CharField(max_length=16, null=False, blank=False, verbose_name=u'字段类型')
    column_length = models.CharField(max_length=8, null=False, blank=False, verbose_name=u'字段长度')
    is_pk = models.BooleanField(default=False, null=False, blank=False, verbose_name=u'主键否')
    is_null = models.BooleanField(default=False, null=False, blank=False, verbose_name=u'可空否')
    is_incr = models.BooleanField(default=False, null=False, blank=False, verbose_name=u'自增否')
    default = models.TextField(null=True, blank=True, verbose_name=u'默认值')
    alias = models.CharField(max_length=128, null=True, blank=True, verbose_name=u'别名')
    label = models.CharField(max_length=128, null=True, blank=True, verbose_name=u'标签')
    remark = RichTextUploadingField(null=True, blank=True, verbose_name=u'备注')
    status = models.CharField(default='0', max_length=1, null=False, blank=False, verbose_name=u'状态',
                              choices=DATADICT_STATUS)
    edt = models.DateTimeField(auto_now_add=True, verbose_name=u'录入时间')
    udt = models.DateTimeField(auto_now=True, verbose_name=u'更新时间')

    def __str__(self):
        return '{}.{}'.format(self.table, self.column)

    class Meta:
        verbose_name = '数据字典'
        verbose_name_plural = '09.数据字典'
        unique_together = ('table', 'column')
        index_together = ('alias', 'status')
