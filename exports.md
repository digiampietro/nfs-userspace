# NAME

exports - NFS file systems being exported

# SYNOPSIS

**/etc/exports**

# DESCRIPTION

The file */etc/exports* serves as the access control list for file
systems which may be exported to NFS clients. It is used by both the NFS
mount daemon, *mountd*(8) and the NFS file server daemon *nfsd*(8).

The file format is similar to the SunOS *exports* file, except that
several additional options are permitted. Each line contains a mount
point and a list of machine or netgroup names allowed to mount the file
system at that point. An optional parenthesized list of mount parameters
may follow each machine name. Blank lines are ignored, and a \#
introduces a comment to the end of the line. Entries may be continued
across newlines using a backslash.

## Machine Name Formats

NFS clients may be specified in a number of ways:

\"single

:   This is the most common format. You may specify a host either by an
    abbreviated name recognizued be the resolver, the fully qualified
    domain name, or an IP address.

\"netgroups

:   NIS netgroups may be given as *\@group*. Only the host part of all
    netgroup members is extracted and added to the access list. Empty
    host parts or those containing a single dash (-) are ignored.

\"wildcards

:   Machine names may contain the wildcard characters *\** and *?*. This
    can be used to make the *exports* file more compact; for instance,
    *\*.cs.foo.edu* matches all hosts in the domain *cs.foo.edu*.
    However, these wildcard characters do not match the dots in a domain
    name, so the above pattern does not include hosts such as
    *a.b.cs.foo.edu*.

\"IP

:   You can also export directories to all hosts on an IP (sub-) network
    simultaneously. This is done by specifying an IP address and netmask
    pair as *address/netmask*.

```{=html}
<!-- -->
```

**=public**

:   This is a special \`\`hostname\'\' that identifies the given
    directory name as the public root directory (see the section on
    WebNFS in **nfsd**(8) for a discussion of WebNFS and the public root
    handle). When using this convention, **=public** must be the only
    entry on this line, and must have no export options associated with
    it. Note that this does *not* actually export the named directory;
    you still have to set the exports options in a separate entry.

The public root path can also be specified by invoking *nfsd* with the
**\--public-root** option. Multiple specifications of a public root will
be ignored.

## General Options

*mountd* and *nfsd* understand the following export options:

*secure*\"

:   This option requires that requests originate on an internet port
    less than IPPORT_RESERVED (1024). This option is on by default. To
    turn it off, specify *insecure*.

*ro*

:   Disallow the client to modify files and directories. The client is
    only allowed to issue read-only requests.

*rw*

:   Allow the client to modify files and directories. This is the
    default.

*noaccess*

:   This makes everything below the directory inaccessible for the named
    client. This is useful when you want to export a directory hierarchy
    to a client, but exclude certain subdirectories. The client\'s view
    of a directory flagged with noaccess is very limited; it is allowed
    to read its attributes, and lookup \`.\' and \`..\'. These are also
    the only entries returned by a readdir.

*link_relative*

:   Convert absolute symbolic links (where the link contents start with
    a slash) into relative links by prepending the necessary number of
    ../\'s to get from the directory containing the link to the root on
    the server. This has subtle, perhaps questionable, semantics when
    the file hierarchy is not mounted at its root.

*link_absolute*

:   Leave all symbolic link as they are. This is the default operation.

## Anonymous Entries

Entries where hosts are not specified are known as anonymous entries.
They have different default settings compared to normal entries. The
differences include *all_squash*, *no_secure*, and *ro*.

## User ID Mapping

*nfsd* bases its access control to files on the server machine on the
uid and gid provided in each NFS RPC request. The normal behavior a user
would expect is that she can access her files on the server just as she
would on a normal file system. This requires that the same uids and gids
are used on the client and the server machine. This is not always true,
nor is it always desirable.

Very often, it is not desirable that the root user on a client machine
is also treated as root when accessing files on the NFS server. To this
end, uid 0 is normally mapped to a different id: the so-called anonymous
or *nobody* uid. This mode of operation (called \`root squashing\') is
the default, and can be turned off with *no_root_squash*.

By default, *nfsd* tries to obtain the anonymous uid and gid by looking
up user *nobody* in the password file at startup time. If it isn\'t
found, a uid and gid of -2 (i.e. 65534) is used. These values can also
be overridden by the *anonuid* and *anongid* options.

In addition to this, *nfsd* lets you specify arbitrary uids and gids
that should be mapped to user nobody as well. Finally, you can map all
user requests to the anonymous uid by specifying the
*all_squash*\"*option.*

For the benefit of installations where uids differ between different
machines, *nfsd* provides several mechanism to dynamically map server
uids to client uids and vice versa: static mapping files, NIS-based
mapping, and *ugidd*-based mapping.

*ugidd*-based mapping is enabled with the *map_daemon* option, and uses
the UGID RPC protocol. For this to work, you have to run the *ugidd*(8)
mapping daemon on the client host. It is the least secure of the three
methods, because by running *ugidd*, everybody can query the client host
for a list of valid user names. You can protect yourself by restricting
access to *ugidd* to valid hosts only. This can be done by entering the
list of valid hosts into the *hosts.allow* or *hosts.deny* file. The
service name is *ugidd*. For a description of the file\'s syntax, please
read *hosts_access*(5).

Static mapping is enabled by using the *map_static* option, which takes
a file name as an argument that describes the mapping. NIS-based mapping
queries the client\'s NIS server to obtain a mapping from user and group
names on the server host to user and group names on the client.

Here\'s the complete list of mapping options:

*root_squash*

:   Map requests from uid/gid 0 to the anonymous uid/gid. Note that this
    does not apply to any other uids that might be equally sensitive,
    such as user *bin*.

*no_root_squash*

:   Turn off root squashing. This option is mainly useful for diskless
    clients.

*squash_uids* and *squash_gids*

:   This option specifies a list of uids or gids that should be subject
    to anonymous mapping. A valid list of ids looks like this:

    *squash_uids=0-15,20,25-50*

    Usually, your squash lists will look a lot simpler.

*all_squash*

:   Map all uids and gids to the anonymous user. Useful for NFS-exported
    public FTP directories, news spool directories, etc. The opposite
    option is *no_all_squash*, which is the default setting.

*map_daemon*

:   This option turns on dynamic uid/gid mapping. Each uid in an NFS
    request will be translated to the equivalent server uid, and each
    uid in an NFS reply will be mapped the other way round. This option
    requires that *rpc.ugidd*(8) runs on the client host. The default
    setting is *map_identity*, which leaves all uids untouched. The
    normal squash options apply regardless of whether dynamic mapping is
    requested or not.

*map_static*

:   This option enables static mapping. It specifies the name of the
    file that describes the uid/gid mapping, e.g.

    *map_static=/etc/nfs/foobar.map*

    The file\'s format looks like this

        # Mapping for client foobar:
        #    remote     local
        uid  0-99       -       # squash these
        uid  100-500    1000    # map 100-500 to 1000-1500
        gid  0-49       -       # squash these
        gid  50-100     700     # map 50-100 to 700-750

*map_nis*

:   This option enables NIS-based uid/gid mapping. For instance, when
    the server encounters the uid 123 on the server, it will obtain the
    login name associated with it, and contact the NFS client\'s NIS
    server to obtain the uid the client associates with the name.

    In order to do this, the NFS server must know the client\'s NIS
    domain. This is specified as an argument to the *map_nis* options,
    e.g.

    *map_nis=foo.com*

    Note that it may not be sufficient to simply specify the NIS domain
    here; you may have to take additional actions before *nfsd* is
    actually able to contact the server. If your distribution uses the
    NYS library, you can specify one or more NIS servers for the
    client\'s domain in */etc/yp.conf*. If you are using a different NIS
    library, you may have to obtain a special *ypbind*(8) daemon that
    can be configured via *yp.conf*.

*anonuid* and *anongid*

:   These options explicitly set the uid and gid of the anonymous
    account. This option is primarily useful for PC/NFS clients, where
    you might want all requests appear to be from one user. As an
    example, consider the export entry for **/home/joe** in the example
    section below, which maps all requests to uid 150 (which is
    supposedly that of user joe).

# EXAMPLE

    # sample /etc/exports file
    /               master(rw) trusty(rw,no_root_squash)
    /projects       proj*.local.domain(rw)
    /usr            *.local.domain(ro) @trusted(rw)
    /home/joe       pc001(rw,all_squash,anonuid=150,anongid=100)
    /pub            (ro,insecure,all_squash)
    /pub/private    (noaccess)

The first line exports the entire filesystem to machines master and
trusty. In addition to write access, all uid squashing is turned off for
host trusty. The second and third entry show examples for wildcard
hostnames and netgroups (this is the entry \`@trusted\'). The fourth
line shows the entry for the PC/NFS client discussed above. Line 5
exports the public FTP directory to every host in the world, executing
all requests under the nobody account. The *insecure* option in this
entry also allows clients with NFS implementations that don\'t use a
reserved port for NFS. The last line denies all NFS clients access to
the private directory.

# CAVEATS

Unlike other NFS server implementations, this *nfsd* allows you to
export both a directory and a subdirectory thereof to the same host, for
instance */usr* and */usr/X11R6*. In this case, the mount options of the
most specific entry apply. For instance, when a user on the client host
accesses a file in */usr/X11R6*, the mount options given in the
*/usr/X11R6* entry apply. This is also true when the latter is a
wildcard or netgroup entry.

# FILES

/etc/exports

# DIAGNOSTICS

An error parsing the file is reported using syslogd(8) as level NOTICE
from a DAEMON whenever nfsd(8) or mountd(8) is started up. Any unknown
host is reported at that time, but often not all hosts are not yet known
to named(8) at boot time, thus as hosts are found they are reported with
the same syslogd(8) parameters.

# SEE ALSO

mountd(8), nfsd(8)
