# GNU General Public License version 2 or any later version.
def split(stream):
    '''return an iterator of individual patches from a stream'''
    def isheader(line, inheader):
        if inheader and line[0] in (' ', '\t'):
            # continuation
            return True
        if line[0] in (' ', '-', '+'):
            # diff line - don't check for header pattern in there
            return False
        l = line.split(': ', 1)
        return len(l) == 2 and ' ' not in l[0]

    def chunk(lines):
        return cStringIO.StringIO(''.join(lines))

    def hgsplit(stream, cur):
        inheader = True

        for line in stream:
            if not line.strip():
                inheader = False
            if not inheader and line.startswith('# HG changeset patch'):
                yield chunk(cur)
                cur = []
                inheader = True

            cur.append(line)

        if cur:
            yield chunk(cur)

    def mboxsplit(stream, cur):
        for line in stream:
            if line.startswith('From '):
                for c in split(chunk(cur[1:])):
                    yield c
                cur = []

            cur.append(line)

        if cur:
            for c in split(chunk(cur[1:])):
                yield c

    def mimesplit(stream, cur):
        def msgfp(m):
            fp = cStringIO.StringIO()
            g = email.Generator.Generator(fp, mangle_from_=False)
            g.flatten(m)
            fp.seek(0)
            return fp

        for line in stream:
            cur.append(line)
        c = chunk(cur)

        m = email.Parser.Parser().parse(c)
        if not m.is_multipart():
            yield msgfp(m)
        else:
            ok_types = ('text/plain', 'text/x-diff', 'text/x-patch')
            for part in m.walk():
                ct = part.get_content_type()
                if ct not in ok_types:
                    continue
                yield msgfp(part)

    def headersplit(stream, cur):
        inheader = False

        for line in stream:
            if not inheader and isheader(line, inheader):
                yield chunk(cur)
                cur = []
                inheader = True
            if inheader and not isheader(line, inheader):
                inheader = False

            cur.append(line)

        if cur:
            yield chunk(cur)

    def remainder(cur):
        yield chunk(cur)

    class fiter(object):
        def __init__(self, fp):
            self.fp = fp

        def __iter__(self):
            return self

        def next(self):
            l = self.fp.readline()
            if not l:
                raise StopIteration
            return l

    inheader = False
    cur = []

    mimeheaders = ['content-type']

    if not hasattr(stream, 'next'):
        # http responses, for example, have readline but not next
        stream = fiter(stream)

    for line in stream:
        cur.append(line)
        if line.startswith('# HG changeset patch'):
            return hgsplit(stream, cur)
        elif line.startswith('From '):
            return mboxsplit(stream, cur)
        elif isheader(line, inheader):
            inheader = True
            if line.split(':', 1)[0].lower() in mimeheaders:
                # let email parser handle this
                return mimesplit(stream, cur)
        elif line.startswith('--- ') and inheader:
            # No evil headers seen by diff start, split by hand
            return headersplit(stream, cur)
        # Not enough info, keep reading

    # if we are here, we have a very plain patch
    return remainder(cur)

                        r'---[ \t].*?^\+\+\+[ \t]|'
                        r'\*\*\*[ \t].*?^---[ \t])', re.MULTILINE|re.DOTALL)
                    subject = subject[pend + 1:].lstrip()
        self.eol = None
        if not self.eol:
            if l.endswith('\r\n'):
                self.eol = '\r\n'
            elif l.endswith('\n'):
                self.eol = '\n'
eolmodes = ['strict', 'crlf', 'lf', 'auto']
    def __init__(self, ui, fname, opener, missing=False, eolmode='strict'):
        self.eolmode = eolmode
        self.eol = None
        self.skew = 0
            lr = linereader(fp, self.eolmode != 'strict')
            lines = list(lr)
            self.eol = lr.eol
            return lines
            if self.eolmode == 'auto':
                eol = self.eol
            elif self.eolmode == 'crlf':
                eol = '\r\n'
            else:
                eol = '\n'

            if self.eolmode != 'strict' and eol and eol != '\n':
                        l = l[:-1] + eol
        horig = h
        if (self.eolmode in ('crlf', 'lf')
            or self.eolmode == 'auto' and self.eol):
            # If new eols are going to be normalized, then normalize
            # hunk data before patching. Otherwise, preserve input
            # line-endings.
            h = h.getnormalized()

        # if there's skew we want to emit the "(offset %d lines)" even
        # when the hunk cleanly applies at start + skew, so skip the
        # fast case code
        if self.skew == 0 and diffhelpers.testhunk(old, self.lines, start) == 0:
            search_start = orig_start + self.skew
            for toponly in [True, False]:
                        self.skew = l - orig_start
                        offset = l - orig_start - fuzzlen
                            msg = _("Hunk #%d succeeded at %d "
                                    "with fuzz %d "
                                    "(offset %d lines).\n")
                            self.ui.warn(msg %
                                (h.number, l + 1, fuzzlen, offset))
                            msg = _("Hunk #%d succeeded at %d "
                            self.ui.note(msg % (h.number, l + 1, offset))
        self.rej.append(horig)
        self.hunk = [desc]
        if lr is not None:
            if context:
                self.read_context_hunk(lr)
            else:
                self.read_unified_hunk(lr)
    def getnormalized(self):
        """Return a copy with line endings normalized to LF."""

        def normalize(lines):
            nlines = []
            for line in lines:
                if line.endswith('\r\n'):
                    line = line[:-2] + '\n'
                nlines.append(line)
            return nlines

        # Dummy object, it is rebuilt manually
        nh = hunk(self.desc, self.number, None, None, False, False)
        nh.number = self.number
        nh.desc = self.desc
        nh.hunk = self.hunk
        nh.a = normalize(self.a)
        nh.b = normalize(self.b)
        nh.starta = self.starta
        nh.startb = self.startb
        nh.lena = self.lena
        nh.lenb = self.lenb
        nh.create = self.create
        nh.remove = self.remove
        return nh

                self.hunk[hunki - 1] = s
                    self.hunk.insert(hunki - 1, u)
            for x in xrange(hlen - 1):
                if self.hunk[x + 1][0] == ' ':
                for x in xrange(hlen - 1):
                    if self.hunk[hlen - bot - 1][0] == ' ':
    # afile is not /dev/null, but afile starts with bfile
    abasedir = afile[:afile.rfind('/') + 1]
    bbasedir = bfile[:bfile.rfind('/') + 1]
    if missing and abasedir == bbasedir and afile.startswith(bfile):
def iterhunks(ui, fp, sourcefile=None):
    lr = linereader(fp)
    empty = None
        newfile = newgitfile = False
            empty = False
                empty = False
                empty = False
            gitworkdone = False
                    gitpatches = scangitpatch(lr, x)[1]
                if gp and (gp.op in ('COPY', 'DELETE', 'RENAME', 'ADD')
                           or gp.mode):
                newgitfile = True
            if empty:
                raise NoHunks
            empty = not gitworkdone
            gitworkdone = False

        if newgitfile or newfile:
            empty = False
    if (empty is None and not gitworkdone) or empty:
def applydiff(ui, fp, changed, strip=1, sourcefile=None, eolmode='strict'):
    If 'eolmode' is 'strict', the patch content and patched file are
    read in binary mode. Otherwise, line endings are ignored when
    patching then normalized according to 'eolmode'.
    for state, values in iterhunks(ui, fp, sourcefile):
                    current_file = patchfile(ui, sourcefile, opener,
                                             eolmode=eolmode)
                    current_file, missing = selectfile(afile, bfile,
                                                       first_hunk, strip)
                    current_file = patchfile(ui, current_file, opener,
                                             missing, eolmode)
    if eolmode.lower() not in eolmodes:
    eolmode = eolmode.lower()
        ret = applydiff(ui, fp, files, strip=strip, eolmode=eolmode)
        if fp != patchobj:
            fp.close()
                patcher = (util.find_exe('gpatch') or util.find_exe('patch')
                           or 'patch')
            yield text[i:i + csize]
class GitDiffRequired(Exception):
    pass
def diff(repo, node1=None, node2=None, match=None, changes=None, opts=None,
         losedatafn=None):
    if node2 is None, compare node1 with working directory.

    losedatafn(**kwarg) is a callable run when opts.upgrade=True and
    every time some change cannot be represented with the current
    patch format. Return False to upgrade to git patch format, True to
    accept the loss or raise an exception to abort the diff. It is
    called with the name of current file being diffed as 'fn'. If set
    to None, patches will always be upgraded to git format when
    necessary.
    '''
        return []
    revs = None
    if not repo.ui.quiet:
        hexfunc = repo.ui.debugflag and hex or short
        revs = [hexfunc(node) for node in [node1, node2] if node]

    copy = {}
    if opts.git or opts.upgrade:
        copy = copies.copies(repo, ctx1, ctx2, repo[nullid])[0]
    difffn = lambda opts, losedata: trydiff(repo, revs, ctx1, ctx2,
                 modified, added, removed, copy, getfilectx, opts, losedata)
    if opts.upgrade and not opts.git:
        try:
            def losedata(fn):
                if not losedatafn or not losedatafn(fn=fn):
                    raise GitDiffRequired()
            # Buffer the whole output until we are sure it can be generated
            return list(difffn(opts.copy(git=False), losedata))
        except GitDiffRequired:
            return difffn(opts.copy(git=True), None)
        return difffn(opts, None)
def _addmodehdr(header, omode, nmode):
    if omode != nmode:
        header.append('old mode %s\n' % omode)
        header.append('new mode %s\n' % nmode)

def trydiff(repo, revs, ctx1, ctx2, modified, added, removed,
            copy, getfilectx, opts, losedatafn):

    date1 = util.datestr(ctx1.date())
    man1 = ctx1.manifest()
    copyto = dict([(v, k) for k, v in copy.items()])

    if opts.git:
        revs = None

        if opts.git or losedatafn:
                if f in copy or f in copyto:
                    if opts.git:
                        if f in copy:
                            a = copy[f]
                        else:
                            a = copyto[f]
                        omode = gitmode[man1.flags(a)]
                        _addmodehdr(header, omode, mode)
                        if a in removed and a not in gone:
                            op = 'rename'
                            gone.add(a)
                        else:
                            op = 'copy'
                        header.append('%s from %s\n' % (op, a))
                        header.append('%s to %s\n' % (op, f))
                        to = getfilectx(a, ctx1).data()
                        losedatafn(f)
                    if opts.git:
                        header.append('new file mode %s\n' % mode)
                    elif ctx2.flags(f):
                        losedatafn(f)
                    if opts.git:
                        dodiff = 'binary'
                    else:
                        losedatafn(f)
                if not opts.git and not tn:
                    # regular diffs cannot represent new empty file
                    losedatafn(f)
                if opts.git:
                    # have we already reported a copy above?
                    if ((f in copy and copy[f] in added
                         and copyto[copy[f]] == f) or
                        (f in copyto and copyto[f] in added
                         and copy[copyto[f]] == f)):
                        dodiff = False
                    else:
                        header.append('deleted file mode %s\n' %
                                      gitmode[man1.flags(f)])
                elif not to:
                    # regular diffs cannot represent empty file deletion
                    losedatafn(f)
                oflag = man1.flags(f)
                nflag = ctx2.flags(f)
                binary = util.binary(to) or util.binary(tn)
                if opts.git:
                    _addmodehdr(header, gitmode[oflag], gitmode[nflag])
                    if binary:
                        dodiff = 'binary'
                elif binary or nflag != oflag:
                    losedatafn(f)
            if opts.git:
                header.insert(0, mdiff.diffline(revs, a, b, opts))

                                    a, b, revs, opts=opts)
        single(rev, seqno + 1, fp)
        maxtotal = max(maxtotal, adds + removes)