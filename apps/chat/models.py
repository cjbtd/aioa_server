from django.db import models


class UserMail(models.Model):
    by = models.CharField(max_length=64, null=False, blank=False, verbose_name=u'发送者')
    me = models.CharField(max_length=64, null=False, blank=False, verbose_name=u'接收者')
    to = models.TextField(null=True, blank=True, verbose_name=u'发送列表')
    cc = models.TextField(null=True, blank=True, verbose_name=u'抄送列表')
    is_read = models.BooleanField(default=False, null=False, blank=False, verbose_name=u'已读')
    is_push = models.BooleanField(default=False, null=False, blank=False, verbose_name=u'已推')
    title = models.CharField(max_length=256, null=False, blank=False, verbose_name=u'主题')
    content = models.TextField(null=False, blank=False, verbose_name=u'正文')
    attachments = models.TextField(null=True, blank=True, verbose_name=u'附件')
    label = models.CharField(max_length=16, null=True, blank=True, verbose_name=u'标签')
    rdt = models.DateTimeField(null=True, blank=True, verbose_name=u'阅读时间')
    edt = models.DateTimeField(auto_now_add=True, verbose_name=u'录入时间')

    def __str__(self):
        return self.title

    class Meta:
        verbose_name = '消息'
        verbose_name_plural = '00.消息'
