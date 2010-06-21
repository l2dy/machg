import base85, cmdutil, mdiff, util, diffhelpers, copies
import cStringIO, email.Parser, os, re
import sys, tempfile, zlib
class NoHunks(PatchError):
    pass

    if os.path.exists(absdst):
    return tuple (filename, message, user, date, node, p1, p2).
                    if line.startswith('# HG changeset patch'):
                    elif hgpatch:
                    if not line.startswith('# ') and not ignoretext:
GP_PATCH  = 1 << 0  # we have to run patch
GP_FILTER = 1 << 1  # there's some copy/rename operation
GP_BINARY = 1 << 2  # there's a binary patch

        self.lineno = 0
    # Can have a git patch with only metadata, causing patch to complain
    dopatch = 0

    lineno = 0
        lineno += 1
                gp.lineno = lineno
                if gp.op in ('COPY', 'RENAME'):
                    dopatch |= GP_FILTER
                dopatch |= GP_PATCH
                # is the deleted file a symlink?
                gp.setmode(int(line[-6:], 8))
                dopatch |= GP_BINARY
    if not gitpatches:
        dopatch = GP_PATCH

    return (dopatch, gitpatches)
        # a symlink. updatedir() will -too magically- take care of
        # setting it to the proper type afterwards.
    def write(self, dest=None):
        if not self.dirty:
            return
        if not dest:
            dest = self.fname
        self.writelines(dest, self.lines)

    def close(self):
        self.write()
        self.write_rej()

                # this can happen when the hunk does not add any lines
def selectfile(afile_orig, bfile_orig, hunk, strip):
    def pathstrip(path, count=1):
        pathlen = len(path)
        i = 0
        if count == 0:
            return '', path.rstrip()
        while count > 0:
            i = path.find('/', i)
            if i == -1:
                raise PatchError(_("unable to strip away %d dirs from %s") %
                                 (count, path))
            # consume '//' in the path
            while i < pathlen - 1 and path[i] == '/':
                i += 1
            count -= 1
        return path[:i].lstrip(), path[i:].rstrip()
    gooda = not nulla and util.lexists(afile)
        goodb = not nullb and os.path.exists(bfile)
    # some diff programs apparently produce create patches where the
    # afile is not /dev/null, but afile starts with bfile
    (dopatch, gitpatches) = readgitpatch(gitlr)
    return dopatch, gitpatches
    empty = None
            empty = False
            try:
                if context is None and x.startswith('***************'):
                    context = True
                gpatch = changed.get(bfile)
                create = afile == '/dev/null' or gpatch and gpatch.op == 'ADD'
                remove = bfile == '/dev/null' or gpatch and gpatch.op == 'DELETE'
                current_hunk = hunk(x, hunknum + 1, lr, context, create, remove)
            except PatchError, err:
                ui.debug(err)
                current_hunk = None
                continue
                empty = False
                empty = False
                    gitpatches = scangitpatch(lr, x)[1]
            if empty:
                raise NoHunks
            empty = not gitworkdone
            empty = False
    if (empty is None and not gitworkdone) or empty:
        raise NoHunks

    """
    Reads a patch from fp and tries to apply it.
    gitpatches = None
    opener = util.opener(os.getcwd())
        current_file.close()
            current_hunk = values
            ret = current_file.apply(current_hunk)
                    current_file = patchfile(ui, sourcefile, opener,
                                             eolmode=eolmode)
                    current_file = patchfile(ui, current_file, opener,
                                             missing, eolmode)
                current_file, current_hunk = None, None
            gitpatches = values
            cwd = os.getcwd()
            for gp in gitpatches:
                if gp.op in ('COPY', 'RENAME'):
                    copyfile(gp.oldpath, gp.path, cwd)
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

def updatedir(ui, repo, patches, similarity=0):
    '''Update dirstate after patch application according to metadata'''
    if not patches:
        return
    copies = []
    removes = set()
    cfiles = patches.keys()
    cwd = repo.getcwd()
    if cwd:
        cfiles = [util.pathto(repo.root, cwd, f) for f in patches.keys()]
    for f in patches:
        gp = patches[f]
        if not gp:
            continue
        if gp.op == 'RENAME':
            copies.append((gp.oldpath, gp.path))
            removes.add(gp.oldpath)
        elif gp.op == 'COPY':
            copies.append((gp.oldpath, gp.path))
        elif gp.op == 'DELETE':
            removes.add(gp.path)
    for src, dst in copies:
        repo.copy(src, dst)
    if (not similarity) and removes:
        repo.remove(sorted(removes), True)
    for f in patches:
        gp = patches[f]
        if gp and gp.mode:
            islink, isexec = gp.mode
            dst = repo.wjoin(gp.path)
            # patch won't create empty files
            if gp.op == 'ADD' and not os.path.exists(dst):
                flags = (isexec and 'x' or '') + (islink and 'l' or '')
                repo.wwrite(gp.path, '', flags)
            elif gp.op != 'DELETE':
                util.set_flags(dst, islink, isexec)
    cmdutil.addremove(repo, cfiles, similarity=similarity)
    files = patches.keys()
    files.extend([r for r in removes if r not in files])
    return sorted(files)

def externalpatch(patcher, args, patchname, ui, strip, cwd, files):
        raise util.Abort(_('Unsupported line endings type: %s') % eolmode)
        raise PatchError
    args = []
            return externalpatch(patcher, args, patchname, ui, strip, cwd,
                                 files)
        else:
            try:
                return internalpatch(patchname, ui, strip, cwd, files, eolmode)
            except NoHunks:
                patcher = (util.find_exe('gpatch') or util.find_exe('patch')
                           or 'patch')
                ui.debug('no valid hunks found; trying with %r instead\n' %
                         patcher)
                if util.needbinarypatch():
                    args.append('--binary')
                return externalpatch(patcher, args, patchname, ui, strip, cwd,
                                     files)
        s = str(err)
        if s:
            raise util.Abort(s)
        else:
            raise util.Abort(_('patch failed to apply'))
            return '0' * 40
         losedatafn=None):
                 modified, added, removed, copy, getfilectx, opts, losedata)
            copy, getfilectx, opts, losedatafn):
                        header.append('%s from %s\n' % (op, a))
                        header.append('%s to %s\n' % (op, f))
                elif not to:
                header.insert(0, mdiff.diffline(revs, a, b, opts))
                                    a, b, revs, opts=opts)
def export(repo, revs, template='hg-%h.patch', fp=None, switch_parent=False,
           opts=None):
    '''export changesets as hg patches.'''

    total = len(revs)
    revwidth = max([len(str(rev)) for rev in revs])

    def single(rev, seqno, fp):
        ctx = repo[rev]
        node = ctx.node()
        parents = [p.node() for p in ctx.parents() if p]
        branch = ctx.branch()
        if switch_parent:
            parents.reverse()
        prev = (parents and parents[0]) or nullid

        if not fp:
            fp = cmdutil.make_file(repo, template, node, total=total,
                                   seqno=seqno, revwidth=revwidth,
                                   mode='ab')
        if fp != sys.stdout and hasattr(fp, 'name'):
            repo.ui.note("%s\n" % fp.name)

        fp.write("# HG changeset patch\n")
        fp.write("# User %s\n" % ctx.user())
        fp.write("# Date %d %d\n" % ctx.date())
        if branch and (branch != 'default'):
            fp.write("# Branch %s\n" % branch)
        fp.write("# Node ID %s\n" % hex(node))
        fp.write("# Parent  %s\n" % hex(prev))
        if len(parents) > 1:
            fp.write("# Parent  %s\n" % hex(parents[1]))
        fp.write(ctx.description().rstrip())
        fp.write("\n\n")

        for chunk in diff(repo, prev, node, opts=opts):
            fp.write(chunk)

    for seqno, rev in enumerate(revs):
        single(rev, seqno + 1, fp)

    for filename, adds, removes, isbinary in stats:
        maxname = max(maxname, len(filename))
    for filename, adds, removes, isbinary in stats:
        output.append(' %-*s |  %*s %s%s\n' % (maxname, filename, countwidth,
                                               count, pluses, minuses))