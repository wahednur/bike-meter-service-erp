"""
URL configuration for config project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
import re

from django.conf import settings
from django.contrib import admin
from django.urls import include, path, re_path
from django.views.static import serve as serve_static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('apps.accounts.urls')),
    path('api/', include('apps.audit.urls')),
    path('api/', include('apps.customers.urls')),
    path('api/', include('apps.suppliers.urls')),
    path('api/', include('apps.meters.urls')),
    path('api/', include('apps.services.urls')),
    path('api/', include('apps.products.urls')),
    path('api/', include('apps.invoices.urls')),
    path('api/', include('apps.assets.urls')),
    path('api/', include('apps.loans.urls')),
    path('api/', include('apps.reports.urls')),
    path('api/', include('apps.notifications.urls')),
    path('api/', include('apps.ecommerce.urls')),
    path('api/', include('apps.expenses.urls')),
    path('api/', include('apps.shop_profile.urls')),
]

# django.conf.urls.static.static() only ever registers this route when
# DEBUG=True (it no-ops otherwise, regardless of any guard around the call
# site) - but this deployment is a single gunicorn service with no separate
# web server or object storage in front of it (see render.yaml, which sets
# DEBUG=False), so Django itself still has to serve uploaded media
# (installment receipts, meter/product/asset photos, etc.) in production,
# or none of it would ever be reachable. Registering the view directly
# sidesteps that DEBUG check.
urlpatterns += [
    re_path(r'^%s(?P<path>.*)$' % re.escape(settings.MEDIA_URL.lstrip('/')), serve_static, {
        'document_root': settings.MEDIA_ROOT,
    }),
]
