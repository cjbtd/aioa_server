import os
import hashlib
from .settings import MEDIA_ROOT, CKEDITOR_UPLOAD_PATH


def ckeditor_media_path(filename, request):
    _, ext = os.path.splitext(filename)

    md = hashlib.md5()
    for data in request.FILES["upload"].chunks(chunk_size=4096):
        md.update(data)

    md5 = md.hexdigest()
    path = request.GET.get('ckeditor_media_path', '').strip('/')
    if '.' in path:
        path = ''
    else:
        pass

    try:
        os.unlink(os.path.join(MEDIA_ROOT, CKEDITOR_UPLOAD_PATH, path, md5 + ext))
        os.unlink(os.path.join(MEDIA_ROOT, CKEDITOR_UPLOAD_PATH, path, md5 + '_thumb' + ext))
    except Exception as _:
        pass

    return os.path.join(path, md5 + ext)
