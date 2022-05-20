from .table import BaseTableUtils
from apps.base.config import SystemConfig
from apps.chat.views import save_mail


def flush_perm(tu: BaseTableUtils, key_perms, key_staffid):
    if key_perms in tu.form_data:
        sc = SystemConfig(tu.get_cell(tu.pk, key_staffid))
        sc.clear()
    else:
        pass


def send_mail(tu: BaseTableUtils, mail: dict, keys: list = None):
    _url = '{}?gid={}&id={}'.format(tu.path, tu.gid, tu.pk or ','.join(tu.pks))

    if keys:
        pk = tu.pk or tu.pks[0]
        vals = tu.get_row(pk, keys)
    else:
        vals = {}

    vals['_url'] = _url

    to = mail.get('to')
    if to:
        to = to.format(**vals)

        cc = mail.get('cc')
        if cc:
            cc = cc.format(**vals)
        else:
            pass

        title = mail.get('title', '').format(**vals)
        content = mail.get('content', '').format(**vals)
        attachments = mail.get('attachments', '').format(**vals)

        save_mail(tu.username, to, cc, title, content, attachments)
    else:
        pass
