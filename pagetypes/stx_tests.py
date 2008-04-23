# -*- coding: utf-8 -*-
from Products.ZWiki.testsupport import *
#ZopeTestCase.installProduct('ZCatalog')
ZopeTestCase.installProduct('ZWiki')

def test_suite():
    suite = unittest.TestSuite()
    suite.addTest(unittest.makeSuite(Tests))
    return suite

class Tests(ZwikiTestCase):

    def test_PageTypeStx(self):
        self.p.edit(text='! PageOne PageTwo\n',type='stx')
        self.assertEquals(self.p.render(bare=1),
                          '<p> PageOne PageTwo</p>\n<p>\n</p>\n')

    def test_non_ascii_edit(self):
        self.p.edit(text='É',type='stx')
        # render returns unicode, use a unicode literal avoid decode problems
        self.assertEquals(u'<p>É</p>\n<p>\n</p>\n', self.p.render(bare=1))
                          
