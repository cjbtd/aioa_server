# Generated by Django 4.0.4 on 2022-05-31 16:37

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0001_initial'),
    ]

    operations = [
        migrations.AlterField(
            model_name='userconf',
            name='user',
            field=models.CharField(max_length=64, verbose_name='账号'),
        ),
        migrations.AlterField(
            model_name='userperm',
            name='user',
            field=models.CharField(max_length=64, verbose_name='账号'),
        ),
        migrations.AlterField(
            model_name='userrole',
            name='user',
            field=models.CharField(max_length=64, verbose_name='账号'),
        ),
    ]
