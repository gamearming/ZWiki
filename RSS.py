# zwiki RSS feed functionality

from __future__ import nested_scopes
import string, re
from string import join
from types import *
from urllib import quote, unquote
from DateTime import DateTime
from AccessControl import ClassSecurityInfo
from Globals import InitializeClass

import Permissions
from Utils import BLATHER, html_quote

from I18n import _

class PageRSSSupport:
    """
    I provide various kinds of RSS feed for the page and the whole wiki.
    """
    security = ClassSecurityInfo()

    security.declareProtected(Permissions.View, 'pages_rss')
    def pages_rss(self, num=10, REQUEST=None):
        """
        Provide an RSS feed showing this wiki's recently created pages.
        """
        feedtitle = self.folder().title_or_id() + ' new pages'
        feeddescription = feedtitle
        feedlanguage = 'en'
        feeddate = self.folder().bobobase_modification_time().rfc822()
        wikiurl = self.wikiUrl()
        REQUEST.RESPONSE.setHeader('Content-Type','text/xml; charset=utf-8')
        t = """\
<rss version="2.0">
<channel>
<title>%(feedtitle)s</title>
<link>%(feedurl)s</link>
<description>%(feeddescription)s</description>
<language>%(feedlanguage)s</language>
<pubDate>%(feeddate)s</pubDate>
""" % {
            'feedtitle':feedtitle,
            'feeddescription':feeddescription,
            'feedurl':wikiurl,
            'feedlanguage':feedlanguage,
            'feeddate':feeddate,
            }
        for p in self.pages(sort_on='creation_time',
                            sort_order='reverse',
                            sort_limit=num,
                            isBoring=0):
            pobj = p.getObject()
            t += """\
<item>
<title>%(title)s</title>
<link>%(wikiurl)s/%(id)s</link>
<guid>%(wikiurl)s/%(id)s</guid>
<description><![CDATA[%(summary)s]]></description>
<pubDate>%(creation_time)s</pubDate>
</item>
""" % {
            'title':p.Title,
            'wikiurl':wikiurl,
            'id':p.id,
            'summary':pobj.summary(1000),
            'creation_time':pobj.creationTime().rfc822(), # be robust here
            }
        #      <description><![CDATA[%(summary)s]]></description>
        t += """\
</channel>
</rss>
"""
        return t

    security.declareProtected(Permissions.View, 'changes_rss')
    def changes_rss(self, num=10, REQUEST=None):
        """
        Provide an RSS feed showing this wiki's recently edited pages.

        This is not the same as all recent edits.
        """
        feedtitle = self.folder().title_or_id() + ' changed pages'
        feeddescription = feedtitle
        feedlanguage = 'en'
        feeddate = self.folder().bobobase_modification_time().rfc822()
        wikiurl = self.wikiUrl()
        REQUEST.RESPONSE.setHeader('Content-Type','text/xml; charset=utf-8')
        t = """\
<rss version="2.0">
<channel>
<title>%(feedtitle)s</title>
<link>%(feedurl)s</link>
<description>%(feeddescription)s</description>
<language>%(feedlanguage)s</language>
<pubDate>%(feeddate)s</pubDate>
""" % {
            'feedtitle':feedtitle,
            'feeddescription':feeddescription,
            'feedurl':wikiurl,
            'feedlanguage':feedlanguage,
            'feeddate':feeddate,
            }
        for p in self.pages(sort_on='last_edit_time',
                            sort_order='reverse',
                            sort_limit=num,
                            isBoring=0):
            pobj = p.getObject()
            t += """\
<item>
<title>%(title)s</title>
<link>%(wikiurl)s/%(id)s</link>
<guid>%(wikiurl)s/%(id)s</guid>
<description>%(last_log)s</description>
<pubDate>%(last_edit_time)s</pubDate>
</item>
""" % {
            'title':'[%s] %s' % (p.Title,html_quote(p.last_log)),
            'wikiurl':wikiurl,
            'id':p.id,
            'last_log':html_quote(pobj.textDiff()),
            'last_edit_time':pobj.lastEditTime().rfc822(), # be robust here
            }
        t += """\
</channel>
</rss>
"""
        return t


InitializeClass(PageRSSSupport) 
