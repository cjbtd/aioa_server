# Generated by Django 4.0.4 on 2022-05-31 16:37

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('chat', '0001_initial'),
    ]

    operations = [
        migrations.AlterField(
            model_name='usermail',
            name='by',
            field=models.CharField(max_length=64, verbose_name='发送者'),
        ),
        migrations.AlterField(
            model_name='usermail',
            name='me',
            field=models.CharField(max_length=64, verbose_name='接收者'),
        ),
    ]
