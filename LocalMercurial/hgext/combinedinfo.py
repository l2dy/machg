#!/usr/bin/env python

'''combinedinfo

Prints the tip, parents, local tags, global tags, bookmarks,
active branches, inactive branches, closed branches, and open heads
'''


import os, sys, binascii
from mercurial import hg

def printFullCombinedInfo(ui, repo, **opts):
    # The doc string below will show up in hg help
    """Print consildated information about the repository.

    Print the tip, parents, local tags, global tags, bookmarks,
    active branches, inactive branches, closed branches, and open heads"""

    # repo can be indexed based on tags, an sha1, or a revision number
    hex = binascii.hexlify
    ctx = repo[None]
    parents = ctx.parents()

    #
    # print tip and parents
    #
    theTip = repo[len(repo) - 1]
    ui.write("tip %d:%s\n" % (theTip, theTip.hex()))
    if (len(parents) >= 1):
        ui.write("parent1 %s:%s\n" % (parents[0].rev(), parents[0].hex()))
    if (len(parents) == 2):
        ui.write("parent2 %s:%s\n" % (parents[1].rev(), parents[1].hex()))

    #
    # compute bookmarks from the .hg/bookmarks file
    #
    bookmarks = set([])
    try:
        for line in repo.opener('bookmarks'):
            sha, refspec = line.strip().split(' ', 1)
            bookmarks.add(sha)
    except:
        pass


    #
    # write out localtags, globaltags, and bookmarks
    #
    for t, n in reversed(repo.tagslist()):
        hn = hex(n) 
        if hn in bookmarks:
            tagtype = "bookmark"
        elif repo.tagtype(t) == 'local':
            tagtype = "localtag"
        else:
            tagtype = "globaltag"
        ui.write("%s %d:%s %s\n" % (tagtype, repo.changelog.rev(n), hn, t))


    #
    # write out the ActiveBranch, InactiveBranch, ClosedBranch
    #
    heads = repo.heads()
    activebranches = [repo[n].branch() for n in heads]
    def testactive(tag, node):
        realhead = tag in activebranches
        open = node in repo.branchheads(tag, closed=False)
        return realhead and open

    branches = sorted([(testactive(tag, node), repo.changelog.rev(node), tag)
                          for tag, node in repo.branchtags().items()],
                      reverse=True)

    for isactive, node, tag in branches:
        hn = repo.lookup(node)
        if isactive:
            label = 'activebranch'
        elif hn not in repo.branchheads(tag, closed=False):
            label = 'closedbranch'
        else:
            label = 'inactivebranch'
        ui.write("%s %s:%s %s\n" % (label, str(node), hex(hn), tag))

    #
    # write out the open heads
    #
    for h in heads:
        ui.write("%s %s:%s\n" % ('openhead', repo[h].rev(), repo[h].hex()))
        

cmdtable = {
    # cmd name        function call
    "combinedinfo": (printFullCombinedInfo, [], "")
}
