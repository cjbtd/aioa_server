from django.http import JsonResponse
from django.shortcuts import render
from aioa.security import encrypt
from aioa.settings import s
from aioa.sql import escape
from aioa.utils import get_val_by_path
from apps.base.views import get_data_book, get_data_dict
from apps.base.config import download_file
from .table import BaseTableUtils
from .tools import handle_tools
from .relations import handle_relations


def index(request):
    tu = TableUtils(request)
    return tu.handle_request()


class TableUtils(BaseTableUtils):
    def handle_request(self):
        if not self.is_authenticated:
            return JsonResponse({'status': s.na})

        cp = self.cp
        request = self.request

        # Autocomplete
        autocomplete = request.GET.get(self.k_autocomplete)
        if autocomplete:
            self.context['data'] = encrypt(self.get_autocomplete_data(autocomplete))
            return JsonResponse(self.context)

        # File download
        f_pk = request.GET.get(self.k_f_pk)
        f_key = request.GET.get(self.k_f_key)
        f_info = request.GET.get(self.k_f_info)
        if f_pk and f_key and f_info:
            f_rel = request.GET.get(self.k_f_rel)
            if f_rel:
                cp = self.parser(get_val_by_path(cp.relations, '{}.kwargs.conf'.format(f_rel)))
            else:
                pass

            if f_info not in self.get_cell(f_pk, f_key, cp):
                return render(request, 'error.html')
            return download_file(f_info)
        else:
            pass

        # Get row data
        pk = request.GET.get(self.k_pk)
        if pk:
            self.sgvs['pk'] = escape(pk)

            _type = request.GET.get(self.k_type, 'e')

            rowdata = self.get_row_data(pk, _type)
            if rowdata:
                self.context['data'] = encrypt(rowdata)
                return JsonResponse(self.context)
            else:
                return JsonResponse({'status': s.na})
        else:
            pass

        # Handle tools
        tool = request.GET.get(self.k_tool)
        if tool is not None:
            handle_tools(self, tool)

            self.context['data'] = encrypt(self.result)
            return JsonResponse(self.context)
        else:
            pass

        # Handle relations
        relation_pk = request.GET.get(self.k_relation_pk)
        if relation_pk:
            self.sgvs['pk'] = escape(relation_pk)

            handle_relations(self, relation_pk, request.GET.get(self.k_relation))

            self.context['data'] = encrypt(self.result)
            return JsonResponse(self.context)
        else:
            pass

        # Edit data
        if self.pk:
            self.handle_edit()
        else:
            pass

        # Verify data
        if self.pks:
            self.handle_verify()
        else:
            pass

        # Query data
        self.handle_select()

        # When init load conf
        if request.GET.get(self.k_init, 'true') == 'true':
            if self.cp.book:
                self.result['book'] = get_data_book(self.cp.book)
                self.result['dicts'] = get_data_dict(self.cp.columns.keys())
            else:
                pass

            self.result['gid'] = self.gid
            self.result['path'] = self.path
            self.result['modules'] = self.modules
            self.result.update(cp.opts())
        else:
            pass

        self.context['data'] = encrypt(self.result)

        return JsonResponse(self.context)
