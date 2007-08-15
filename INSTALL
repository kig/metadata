Installing Programs with setup.rb
=================================
    
Quick Start
-----------
    
  Type this (You might needs super user previledge):

      ($ su)
       # ruby setup.rb

  If you want to install a program in to your home directory
  ($HOME), use following instead:

      $ ruby setup.rb all --prefix=$HOME

    
Detailed Installtion Process
----------------------------
    
  setup.rb invokes installation by three steps.  There are
  "config", "setup" and "install".  You can invoke each steps
  separately as following:

      $ ruby setup.rb config
      $ ruby setup.rb setup
      # ruby setup.rb install

  You can controll installation process by giving detailed
  options for each tasks.  For example, --bin-dir=$HOME/bin
  let setup.rb install commands in $HOME/bin.
    
  For details, see "Task Options".
    
  Global Options
  --------------
    
  "Global Option" is a command line option which you can use
  for all tasks.  You must give a global option before any task
  name.
    
    -q,--quiet
        suppress message outputs
    --verbose
        output messages verbosely (default)
    -h,--help
        prints help and quit
    -v,--version
        prints version and quit
    --copyright
        prints copyright and quit
    
Tasks
-----
  These are acceptable tasks:
    all
        Invokes `config', `setup', then `install'.
        Task options for all is same with config.
    config
        Checks and saves configurations.
    show
        Prints current configurations.
    setup
        Compiles ruby extentions.
    install
        Installs files.
    clean
        Removes created files.
    distclean
        Removes all created files.
    
  Task Options for CONFIG/ALL
  ---------------------------
    
    --prefix=PATH
        a prefix of the installing directory path
    --stdruby=PATH
        the directory for standard ruby libraries
    --siterubycommon=PATH
        the directory for version-independent non-standard
        ruby libraries
    --siteruby=PATH
        the directory for non-standard ruby libraries
    --bindir=PATH
        the directory for commands
    --rbdir=PATH
        the directory for ruby scripts
    --sodir=PATH
        the directory for ruby extentions
    --datadir=PATH
        the directory for shared data
    --rubypath=PATH
        path to set to #! line
    --rubyprog=PATH
        the ruby program using for installation
    --makeprog=NAME
        the make program to compile ruby extentions
    --without-ext
        forces to setup.rb never to compile/install
        ruby extentions.
    --rbconfig=PATH
        your rbconfig.rb to load
    
  You can view default values of these options by typing

      $ ruby setup.rb --help

    
  If there's the directory named "packages",
  You can also use these options:
    --with=NAME,NAME,NAME...
        Package names which you want to install.
    --without=NAME,NAME,NAME...
        Package names which you do not want to install.
    
  [NOTE] You can pass options for extconf.rb like this:

      ruby setup.rb config -- --with-tklib=/usr/lib/libtk-ja.so.8.0

    
  Task Options for INSTALL
  ------------------------
    
    --no-harm
        prints what to do and done nothing really.
    --prefix=PATH
        The prefix of the installing directory path.
        This option may help binary package maintainers.
        A default value is an empty string.
