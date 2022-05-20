# Generated by Django 4.0.4 on 2022-05-06 21:25

import ckeditor_uploader.fields
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Config',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=64, verbose_name='名称')),
                ('conf', models.TextField(default='{}', verbose_name='配置')),
                ('type', models.CharField(choices=[('1', '配置'), ('2', '权限'), ('3', '流程'), ('4', '标准'), ('5', '列表'), ('6', '字典'), ('7', '文本'), ('8', '网页'), ('9', '语句')], default='1', max_length=1, verbose_name='类型')),
                ('remark', models.TextField(blank=True, null=True, verbose_name='备注')),
                ('edt', models.DateTimeField(auto_now_add=True, verbose_name='录入时间')),
                ('udt', models.DateTimeField(auto_now=True, verbose_name='更新时间')),
            ],
            options={
                'verbose_name': '配置',
                'verbose_name_plural': '00.配置',
                'unique_together': {('name',)},
            },
        ),
        migrations.CreateModel(
            name='DataBook',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('db', models.CharField(max_length=32, verbose_name='数据库')),
                ('table', models.CharField(max_length=128, verbose_name='数据表')),
                ('label', models.CharField(blank=True, max_length=128, null=True, verbose_name='标签')),
                ('remark', ckeditor_uploader.fields.RichTextUploadingField(blank=True, null=True, verbose_name='备注')),
                ('enable', models.BooleanField(default=True, verbose_name='启用')),
                ('edt', models.DateTimeField(auto_now_add=True, verbose_name='录入时间')),
                ('udt', models.DateTimeField(auto_now=True, verbose_name='更新时间')),
            ],
            options={
                'verbose_name': '数据手册',
                'verbose_name_plural': '08.数据手册',
                'unique_together': {('db', 'table')},
            },
        ),
        migrations.CreateModel(
            name='Menu',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('path', models.CharField(max_length=64, verbose_name='路由')),
                ('name', models.CharField(help_text='层级分割符：/', max_length=128, verbose_name='菜单')),
                ('sort', models.IntegerField(default=1000, help_text='数字小的在前面', verbose_name='排序')),
                ('meta', models.TextField(default='{}', verbose_name='属性')),
                ('relations', models.CharField(blank=True, help_text='分割符：,', max_length=1024, null=True, verbose_name='关联路由')),
                ('enable', models.BooleanField(default=True, verbose_name='启用')),
                ('edt', models.DateTimeField(auto_now_add=True, verbose_name='录入时间')),
                ('udt', models.DateTimeField(auto_now=True, verbose_name='更新时间')),
            ],
            options={
                'verbose_name': '菜单',
                'verbose_name_plural': '01.菜单',
                'ordering': ['sort', 'id'],
                'unique_together': {('path',)},
            },
        ),
        migrations.CreateModel(
            name='Module',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('label', models.CharField(help_text='菜单下必须唯一', max_length=32, verbose_name='模块名')),
                ('value', models.IntegerField(default=0, help_text='菜单下必须唯一', verbose_name='模块值')),
                ('sort', models.IntegerField(default=100, help_text='数字小的在前面', verbose_name='排序')),
                ('enable', models.BooleanField(default=True, verbose_name='启用')),
                ('edt', models.DateTimeField(auto_now_add=True, verbose_name='录入时间')),
                ('udt', models.DateTimeField(auto_now=True, verbose_name='更新时间')),
                ('base_config', models.ForeignKey(default=1, on_delete=django.db.models.deletion.CASCADE, related_name='base_config_id', to='base.config', verbose_name='基础配置')),
                ('menu', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='base.menu', verbose_name='菜单')),
                ('over_config', models.ForeignKey(default=1, on_delete=django.db.models.deletion.CASCADE, related_name='over_config_id', to='base.config', verbose_name='附加配置')),
                ('spec_config', models.ForeignKey(default=1, on_delete=django.db.models.deletion.CASCADE, related_name='spec_config_id', to='base.config', verbose_name='特殊配置')),
            ],
            options={
                'verbose_name': '模块',
                'verbose_name_plural': '02.模块',
                'unique_together': {('menu', 'label', 'value')},
            },
        ),
        migrations.CreateModel(
            name='Role',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=32, verbose_name='角色')),
                ('is_post', models.BooleanField(default=False, verbose_name='岗位')),
                ('enable', models.BooleanField(default=True, verbose_name='启用')),
                ('edt', models.DateTimeField(auto_now_add=True, verbose_name='录入时间')),
                ('udt', models.DateTimeField(auto_now=True, verbose_name='更新时间')),
            ],
            options={
                'verbose_name': '角色',
                'verbose_name_plural': '03.角色',
                'unique_together': {('name',)},
            },
        ),
        migrations.CreateModel(
            name='UserConf',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('user', models.CharField(max_length=8, verbose_name='账号')),
                ('conf', models.TextField(default='{}', verbose_name='配置')),
                ('remark', models.TextField(blank=True, null=True, verbose_name='备注')),
                ('edt', models.DateTimeField(auto_now_add=True, verbose_name='录入时间')),
                ('udt', models.DateTimeField(auto_now=True, verbose_name='更新时间')),
            ],
            options={
                'verbose_name': '个人配置',
                'verbose_name_plural': '07.个人配置',
                'unique_together': {('user',)},
            },
        ),
        migrations.CreateModel(
            name='UserRole',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('user', models.CharField(max_length=8, verbose_name='账号')),
                ('enable', models.BooleanField(default=True, verbose_name='启用')),
                ('edt', models.DateTimeField(auto_now_add=True, verbose_name='录入时间')),
                ('udt', models.DateTimeField(auto_now=True, verbose_name='更新时间')),
                ('role', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='base.role', verbose_name='角色')),
            ],
            options={
                'verbose_name': '账号角色',
                'verbose_name_plural': '05.账号角色',
                'unique_together': {('user', 'role')},
            },
        ),
        migrations.CreateModel(
            name='UserPerm',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('user', models.CharField(max_length=8, verbose_name='账号')),
                ('remark', models.TextField(blank=True, null=True, verbose_name='备注')),
                ('enable', models.BooleanField(default=True, verbose_name='启用')),
                ('edt', models.DateTimeField(auto_now_add=True, verbose_name='录入时间')),
                ('udt', models.DateTimeField(auto_now=True, verbose_name='更新时间')),
                ('module', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='base.module', verbose_name='模块')),
                ('perm_config', models.ForeignKey(default=2, on_delete=django.db.models.deletion.CASCADE, related_name='user_perm_config_id', to='base.config', verbose_name='权限配置')),
            ],
            options={
                'verbose_name': '账号权限',
                'verbose_name_plural': '06.账号权限',
                'unique_together': {('user', 'module')},
            },
        ),
        migrations.CreateModel(
            name='RolePerm',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('enable', models.BooleanField(default=True, verbose_name='启用')),
                ('edt', models.DateTimeField(auto_now_add=True, verbose_name='录入时间')),
                ('udt', models.DateTimeField(auto_now=True, verbose_name='更新时间')),
                ('module', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='base.module', verbose_name='模块')),
                ('perm_config', models.ForeignKey(default=2, on_delete=django.db.models.deletion.CASCADE, related_name='role_perm_config_id', to='base.config', verbose_name='权限配置')),
                ('role', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='base.role', verbose_name='角色')),
            ],
            options={
                'verbose_name': '角色权限',
                'verbose_name_plural': '04.角色权限',
                'unique_together': {('role', 'module')},
            },
        ),
        migrations.CreateModel(
            name='DataDict',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('column', models.CharField(max_length=128, verbose_name='字段')),
                ('column_id', models.SmallIntegerField(verbose_name='字段序号')),
                ('column_type', models.CharField(max_length=16, verbose_name='字段类型')),
                ('column_length', models.CharField(max_length=8, verbose_name='字段长度')),
                ('is_pk', models.BooleanField(default=False, verbose_name='主键否')),
                ('is_null', models.BooleanField(default=False, verbose_name='可空否')),
                ('is_incr', models.BooleanField(default=False, verbose_name='自增否')),
                ('default', models.TextField(blank=True, null=True, verbose_name='默认值')),
                ('alias', models.CharField(blank=True, max_length=128, null=True, verbose_name='别名')),
                ('label', models.CharField(blank=True, max_length=128, null=True, verbose_name='标签')),
                ('remark', ckeditor_uploader.fields.RichTextUploadingField(blank=True, null=True, verbose_name='备注')),
                ('status', models.CharField(choices=[('0', '未审核'), ('1', '已审核'), ('2', '不一致'), ('3', '已废弃'), ('4', '已删除')], default='0', max_length=1, verbose_name='状态')),
                ('edt', models.DateTimeField(auto_now_add=True, verbose_name='录入时间')),
                ('udt', models.DateTimeField(auto_now=True, verbose_name='更新时间')),
                ('table', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='base.databook', verbose_name='数据表')),
            ],
            options={
                'verbose_name': '数据字典',
                'verbose_name_plural': '09.数据字典',
                'unique_together': {('table', 'column')},
                'index_together': {('alias', 'status')},
            },
        ),
    ]
