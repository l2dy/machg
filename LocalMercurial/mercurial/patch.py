import cStringIO, email.Parser, os, re
import tempfile, zlib

import base85, mdiff, util, diffhelpers, copies, encoding
    if os.path.lexists(absdst):
    return tuple (filename, message, user, date, branch, node, p1, p2).
                hgpatchheader = False
                    if line.startswith('# HG changeset patch') and not hgpatch:
                        hgpatchheader = True
                    elif hgpatchheader:
                        elif not line.startswith("# "):
                            hgpatchheader = False
                    if not hgpatchheader and not ignoretext:
    def __repr__(self):
        return "<patchmeta %s %r>" % (self.op, self.path)

    return gitpatches
        # a symlink. cmdutil.updatedir will -too magically- take care
        # of setting it to the proper type afterwards.
                # lines addition, old block is empty
                # XXX: the only way to hit this is with an invalid line range.
                # The no-eol marker is not counted in the line range, but I
                # guess there are diff(1) out there which behave differently.
                # line deletions, new block is empty and we hit EOF
                # line deletions, new block is empty
def pathstrip(path, strip):
    pathlen = len(path)
    i = 0
    if strip == 0:
        return '', path.rstrip()
    count = strip
    while count > 0:
        i = path.find('/', i)
        if i == -1:
            raise PatchError(_("unable to strip away %d of %d dirs from %s") %
                             (count, strip, path))
        i += 1
        # consume '//' in the path
        while i < pathlen - 1 and path[i] == '/':
        count -= 1
    return path[:i].lstrip(), path[i:].rstrip()
def selectfile(afile_orig, bfile_orig, hunk, strip):
    gooda = not nulla and os.path.lexists(afile)
        goodb = not nullb and os.path.lexists(bfile)
    # some diff programs apparently produce patches where the afile is
    # not /dev/null, but afile starts with bfile
    gitpatches = readgitpatch(gitlr)
    return gitpatches
            if context is None and x.startswith('***************'):
                context = True
            gpatch = changed.get(bfile)
            create = afile == '/dev/null' or gpatch and gpatch.op == 'ADD'
            remove = bfile == '/dev/null' or gpatch and gpatch.op == 'DELETE'
            current_hunk = hunk(x, hunknum + 1, lr, context, create, remove)
                    gitpatches = scangitpatch(lr, x)
    """Reads a patch from fp and tries to apply it.

    Callers probably want to call 'cmdutil.updatedir' after this to
    apply certain categories of changes not done by this function.
    return _applydiff(
        ui, fp, patchfile, copyfile,
        changed, strip=strip, sourcefile=sourcefile, eolmode=eolmode)


def _applydiff(ui, fp, patcher, copyfn, changed, strip=1,
               sourcefile=None, eolmode='strict'):
    cwd = os.getcwd()
    opener = util.opener(cwd)
        if current_file.dirty:
            current_file.writelines(current_file.fname, current_file.lines)
        current_file.write_rej()
            ret = current_file.apply(values)
                    current_file = patcher(ui, sourcefile, opener,
                                           eolmode=eolmode)
                    current_file = patcher(ui, current_file, opener,
                                           missing=missing, eolmode=eolmode)
                current_file = None
            for gp in values:
                gp.path = pathstrip(gp.path, strip - 1)[1]
                if gp.oldpath:
                    gp.oldpath = pathstrip(gp.oldpath, strip - 1)[1]
                # Binary patches really overwrite target files, copying them
                # will just make it fails with "target file exists"
                if gp.op in ('COPY', 'RENAME') and not gp.binary:
                    copyfn(gp.oldpath, gp.path, cwd)
def externalpatch(patcher, patchname, ui, strip, cwd, files):
    args = []
        raise util.Abort(_('unsupported line endings type: %s') % eolmode)
        raise PatchError(_('patch failed to apply'))
            return externalpatch(patcher, patchname, ui, strip, cwd, files)
        return internalpatch(patchname, ui, strip, cwd, files, eolmode)
        raise util.Abort(str(err))
            return hex(nullid)
def diffopts(ui, opts=None, untrusted=False):
    def get(key, name=None, getter=ui.configbool):
        return ((opts and opts.get(key)) or
                getter('diff', name or key, None, untrusted=untrusted))
    return mdiff.diffopts(
        text=opts and opts.get('text'),
        git=get('git'),
        nodates=get('nodates'),
        showfunc=get('show_function', 'showfunc'),
        ignorews=get('ignore_all_space', 'ignorews'),
        ignorewsamount=get('ignore_space_change', 'ignorewsamount'),
        ignoreblanklines=get('ignore_blank_lines', 'ignoreblanklines'),
        context=get('unified', getter=ui.config))

         losedatafn=None, prefix=''):

    prefix is a filename prefix that is prepended to all filenames on
    display (used for subrepos).
                 modified, added, removed, copy, getfilectx, opts, losedata, prefix)
def difflabel(func, *args, **kw):
    '''yields 2-tuples of (output, label) based on the output of func()'''
    prefixes = [('diff', 'diff.diffline'),
                ('copy', 'diff.extended'),
                ('rename', 'diff.extended'),
                ('old', 'diff.extended'),
                ('new', 'diff.extended'),
                ('deleted', 'diff.extended'),
                ('---', 'diff.file_a'),
                ('+++', 'diff.file_b'),
                ('@@', 'diff.hunk'),
                ('-', 'diff.deleted'),
                ('+', 'diff.inserted')]

    for chunk in func(*args, **kw):
        lines = chunk.split('\n')
        for i, line in enumerate(lines):
            if i != 0:
                yield ('\n', '')
            stripline = line
            if line and line[0] in '+-':
                # highlight trailing whitespace, but only in changed lines
                stripline = line.rstrip()
            for prefix, label in prefixes:
                if stripline.startswith(prefix):
                    yield (stripline, label)
                    break
            else:
                yield (line, '')
            if line != stripline:
                yield (line[len(stripline):], 'diff.trailingwhitespace')

def diffui(*args, **kw):
    '''like diff(), but yields 2-tuples of (output, label) for ui.write()'''
    return difflabel(diff, *args, **kw)


            copy, getfilectx, opts, losedatafn, prefix):

    def join(f):
        return os.path.join(prefix, f)
                        header.append('%s from %s\n' % (op, join(a)))
                        header.append('%s to %s\n' % (op, join(f)))
                # In theory, if tn was copied or renamed we should check
                # if the source is binary too but the copy record already
                # forces git mode.
                elif not to or util.binary(to):
                header.insert(0, mdiff.diffline(revs, join(a), join(b), opts))
                                    join(a), join(b), revs, opts=opts)

    sized = [(filename, adds, removes, isbinary, encoding.colwidth(filename))
             for filename, adds, removes, isbinary in stats]

    for filename, adds, removes, isbinary, namewidth in sized:
        maxname = max(maxname, namewidth)
    for filename, adds, removes, isbinary, namewidth in sized:
        output.append(' %s%s |  %*s %s%s\n' %
                      (filename, ' ' * (maxname - namewidth),
                       countwidth, count,
                       pluses, minuses))

def diffstatui(*args, **kw):
    '''like diffstat(), but yields 2-tuples of (output, label) for
    ui.write()
    '''

    for line in diffstat(*args, **kw).splitlines():
        if line and line[-1] in '+-':
            name, graph = line.rsplit(' ', 1)
            yield (name + ' ', '')
            m = re.search(r'\++', graph)
            if m:
                yield (m.group(0), 'diffstat.inserted')
            m = re.search(r'-+', graph)
            if m:
                yield (m.group(0), 'diffstat.deleted')
        else:
            yield (line, '')
        yield ('\n', '')