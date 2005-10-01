# Zwiki/zwiki.org makefile

# simple no-branch release process
# --------------------------------
# check for unrecorded changes
# check tests pass
# check for late tracker issues
# check showAccessKeys,README,wikis/,skins/,zwiki.org HelpPage,QuickReference
# update CHANGES.txt from darcs changes (XXX automate brief changes listing)
# update version.txt
# make Release
# update KnownIssues,OldKnownIssues,#zwiki
# mail announcement to zwiki@zwiki.org, zope-announce@zope.org

PRODUCT=ZWiki
HOST=zwiki.org
REPO=$(HOST):/repos/$(PRODUCT)
RSYNCPATH=$(HOST):/repos/$(PRODUCT)
LHOST=localhost:8080
CURL=curl -o.curllog -sS -n

## misc

default: test

epydoc:
	PYTHONPATH=/zope/lib/python \
	 epydoc --docformat restructuredtext \
	        --output /var/www/zopewiki.org/epydoc  \
	        /zope/lib/python/Products/* /zope2/Products/*

epydoc2:
	PYTHONPATH=. \
	cd /zope/lib/python; \
	epydoc \
	-o /var/www/zopewiki.org/epydoc \
	-n Zope-2.7.1b2 \
	AccessControl/ App BDBStorage/ DateTime/ DBTab/ DocumentTemplate/ HelpSys/ OFS/ Persistence/ SearchIndex/ Shared/ Signals/ StructuredText/ TAL/ webdav/ ZClasses/ ZConfig/ zExceptions/ zLOG/ Zope ZopeUndo/ ZPublisher/ ZServer/ ZTUtils/ PageTemplates ExternalMethod Mailhost MIMETools OFSP PluginIndexes PythonScripts Sessions SiteAccess SiteErrorLog


## i18n
# remember: 1. merge source files 2. make pot 3. replace po files 4. make po
# using zope 3's i18nextract.py with zopewiki/ZopeInternationalization patches

LANGUAGES=en es fr-CA fr ga it zh-TW pt-BR zh-CN pl nl de hu fi he ru ja pt
ZOPE3=/usr/local/src/Zope3.1
EXTRACT=PYTHONPATH=$(ZOPE3)/src python $(ZOPE3)/utilities/i18nextract.py

pot: dtmlextract
	$(EXTRACT) -d zwiki -p . -o ./i18n \
	    -x _darcs -x .old -x misc -x ftests 
	tail +12 i18n/zwiki-manual.pot >>i18n/zwiki.pot
	python \
	-c "import re; \
	    t = open('i18n/zwiki.pot').read(); \
	    t = re.sub(r'(?s)^.*?msgid',r'msgid',t); \
	    t = re.sub(r'Zope 3 Developers <zope3-dev@zope.org>',\
	               r'<zwiki@zwiki.org>', \
	               t); \
	    t = re.sub(r'(?s)(\"Generated-By:.*?\n)', \
	               r'\1\"Language-code: xx\\\n\"\n\"Language-name: X\\\n\"\n\"Preferred-encodings: utf-8 latin1\\\n\"\n\"Domain: zwiki\\\n\"\n', \
	               t); \
	    open('i18n/zwiki.pot','w').write(t)"
	rm -f skins/dtmlmessages.pt

# a dtml extraction hack, should integrate with i18nextract
dtmlextract: 
	echo '<div i18n:domain="zwiki">' >skins/dtmlmessages.pt
	find skins wikis -name "*dtml" | xargs perl -n -e '/<dtml-translate domain="?zwiki"?>(.*?)<\/dtml-translate>/ and print "<span i18n:translate=\"\">$$1<\/span>\n";' >>skins/dtmlmessages.pt
	echo '</div>' >>skins/dtmlmessages.pt

po:
	cd i18n; \
	for L in $(LANGUAGES); do \
	 msgmerge -U zwiki-$$L.po zwiki.pot; \
	 msgmerge -U zwiki-plone-$$L.po zwiki-plone.pot; \
	 done

# PTS generates these, this is just for additional checking and stats
mo:
	cd i18n; \
	for L in $(LANGUAGES); do \
	 echo $$L; \
	 msgfmt --statistics zwiki-$$L.po -o zwiki-$$L.mo; \
	 msgfmt --statistics zwiki-plone-$$L.po -o zwiki-plone-$$L.mo; \
	 done; \
	rm -f *.mo

## testing
# to run Zwiki unit tests, you probably need:
# Zope 2.7.3 or greater
# ZopeTestCase, linked under .../lib/python/Testing
# CMF 1.5
# Plone 
# PlacelessTranslationService ? maybe

# all tests, test.py
# avoid mailin tests hanging due to #1104
WHICH_TESTS=''

test:
	zopectl test --libdir . -v $(WHICH_TESTS)

testd:
	zopectl test --libdir . -v -D $(WHICH_TESTS)

# silliness to properly capture output of a test run
testresults:
	date >.testresults 
	make -s test >>.testresults 2>.stderr
	cat .stderr >>.testresults
	rm -f .stderr

# old:

# all tests, gui
gtest:
	PYTHONPATH=/zope/lib/python SOFTWARE_HOME=/zope/lib/python INSTANCE_HOME=/zope2 \
	  python /zope/test.py -m --libdir .

# a single test module in one of the tests directories
testpl%:
	PYTHONPATH=/zope/lib/python SOFTWARE_HOME=/zope/lib/python INSTANCE_HOME=/zope2 \
	  python plugins/tests/test$*.py

testpt%:
	PYTHONPATH=/zope/lib/python SOFTWARE_HOME=/zope/lib/python INSTANCE_HOME=/zope2 \
	  python pagetypes/tests/test$*.py

test%:
	PYTHONPATH=/zope/lib/python SOFTWARE_HOME=/zope/lib/python INSTANCE_HOME=/zope2 \
	  python tests/test$*.py

# test with argument(s)
#test%:
#	export PYTHONPATH=/zope/lib/python:/zope2; \
#	  python test.py -v --libdir $$PWD/tests $*

#XXX currently broken
rtest:
	ssh $(HOST) 'cd zwiki; make test'

rtest%:
	ssh $(HOST) "cd zwiki; make rtest$*"

#ftest:
#	ssh zwiki.org /usr/local/zope/instance/Products/ZWiki/functionaltests/run_tests -v zwiki


## upload (rsync and darcs)

rcheck:
	rsync -ruvC -e ssh -n . $(RSYNCPATH)

rpush:
	rsync -ruvC -e ssh . $(RSYNCPATH)

check: 
	darcs whatsnew --summary

push:
	darcs push -v -a $(REPO)

push-exp:
	darcs push -v -a $(HOST):/repos/$(PRODUCT)-exp

pull-simon: 
	darcs pull --interactive -v http://zwiki.org/repos/ZWiki

pull-lele: 
	darcs pull --interactive -v http://nautilus.homeip.net/~lele/projects/ZWiki

pull-bob: 
	darcs pull --interactive -v http://bob.mcelrath.org/darcs/zwiki

pull-bobtest: 
	darcs pull --interactive -v http://bob.mcelrath.org/darcs/zwiki-testing

pull-bill: 
	darcs pull --interactive -v http://page.axiom-developer.org/repository/ZWiki

## release

VERSION:=$(shell cut -c7- version.txt )
MAJORVERSION:=$(shell echo $(VERSION) | sed -e's/-[^-]*$$//')
VERSIONNO:=$(shell echo $(VERSION) | sed -e's/-/./g')
FILE:=$(PRODUCT)-$(VERSIONNO).tgz

Release: releasenotes version releasetag tarball push rpush

# record CHANGES.txt.. 
releasenotes:
	@echo recording release notes
	@darcs record -am 'update release notes' CHANGES.txt

# bump version number in various places and record; don't have other
# changes in these files
version:
	@echo bumping version to $(VERSIONNO)
	@(echo 'Zwiki' $(VERSIONNO) `date +%Y/%m/%d`; echo)|cat - CHANGES.txt \
	  >.temp; mv .temp CHANGES.txt
	@perl -pi -e "s/__version__='.*?'/__version__='$(VERSIONNO)'/" \
	  __init__.py
	@perl -pi -e "s/Zwiki version [0-9a-z.-]+/Zwiki version $(VERSIONNO)/"\
	  wikis/basic/HelpPage.stx
	@darcs record -am 'bump version to $(VERSIONNO)' \
	  version.txt CHANGES.txt __init__.py wikis/basic/HelpPage.stx

releasetag:
	@echo tagging release-$(VERSION)
	@darcs tag --checkpoint -m release-$(VERSION) 

# always puts tarball in mainbranch/releases
# look at darcs dist
tarball: clean
	@echo building $(FILE) tarball
	@cp -r _darcs/current $(PRODUCT)
	@tar -czvf $(HOME)/zwiki/releases/$(FILE) --exclude Makefile $(PRODUCT)
	@rm -rf $(PRODUCT)


# misc

tags:
	find $$PWD/ -name '*.py' -o  -name '*dtml' -o -name '*.pt' \
	  -o -name '*.css' -o -name '*.pot' -o -name '*.po' \
	  -o -name _darcs  -prune -type f \
	  -o -name contrib -prune -type f \
	  -o -name misc    -prune -type f \
	  -o -name old     -prune -type f \
	  -o -name .old     -prune -type f \
	  -o -name doxygen -prune -type f \
	  -o -name .doxygen -prune -type f \
	  | xargs etags

zopetags:
	cd /zope/lib/python; \
	  ~/bin/eptags.py `find $$PWD/ -name '*.py' -o  -name '*.dtml' -o -name '*.pt' \
	     -o -name old     -prune -type f `

getproducts:
	cd /zope2/Products; \
	  rsync -rl --progress --exclude="*.pyc" zwiki.org:/zope2/Products . 

producttags:
	cd /zope2/Products; \
	  ~/bin/eptags.py `find $$PWD/ -name '*.py' -o  -name '*.dtml' -o -name '*.pt' \
	     -o -name old -o -name .old    -prune -type f ` 

plonetags:
	cd /zope2/Products/CMFPlone; \
	  ~/bin/eptags.py \
	  `find $$PWD/ -name '*.py' -o -name '*.dtml' -o -name '*.pt' \
	     -o -name old     -prune -type f `

alltags: tags producttags zopetags
	cat TAGS /zope2/Products/TAGS /zope/lib/python/TAGS >TAGS.all

clean:
	rm -f .*~ *~ *.tgz *.bak `find . -name "*.pyc"`

Clean: clean
	rm -f i18n/*.mo skins/dtmlmessages.pt


# misc automation examples

refresh-%.po:
	@echo refreshing $(PRODUCT) $*.po file on $(HOST)
	@$(CURL) 'http://$(HOST)/Control_Panel/TranslationService/ZWiki.i18n-$*.po/reload'

refresh: refresh-$(PRODUCT)

refresh-%:
	@echo refreshing $* product on $(HOST)
	@$(CURL) 'http://$(HOST)/Control_Panel/Products/$*/manage_performRefresh'

refresh-mailin:
	@echo refreshing mailin.py external method on $(HOST)
	@$(CURL) 'http://$(HOST)/mailin/manage_edit?id=mailin&module=mailin&function=mailin&title='

lrefresh: lrefresh-$(PRODUCT)

lrefresh-%:
	@echo refreshing product $* on $(LHOST)
	curl -n -sS -o.curllog 'http://$(LHOST)/Control_Panel/Products/$*/manage_performRefresh'

#fixissuepermissions:
#	for ISSUE in 0001 0002 0003 0004 0005 0006 0007 0008 0009 0010; do \
#	  echo "$(HOST): fixing permissions for IssueNo$$ISSUE" ;\
#	  $(CURL) "http://$(HOST)/IssueNo$$ISSUE/manage_permission?permission_to_manage=Change+ZWiki+Page+Types" ;\
#	done
#
#fixcreationtimes:
#	for ISSUE in 0001 0002 0003 0004 0005 0006 0007 0008 0009 0010\
#	  0011 0012 0013 0014 0015 0016 0017 0018 0019 0020\
#	  0021 0022 0023 0024 0025 0026 0027 0028 0029 0030\
#	  0031 0032 0033 0034 0035 0036 0037 0038 0039 0040\
#	  0041 0042 0043 0044 0045 0046 0047 0048 0049 0050\
#	  0051 0052 0053 0054; do \
#	  echo "$(HOST): fixing creation time for IssueNo$$ISSUE" ;\
#	  $(CURL) "http://$(HOST)/IssueNo$$ISSUE/manage_changeProperties?creation_time=2001/11/26+18%3A09+PST" ;\
#	done
#
#updatecatalog:
#	@echo updating Catalog on $(HOST)
#	@$(CURL) "http://$(HOST)/Catalog/manage_catalogReindex"
