name             'celebdating'
maintainer       'Neon Labs'
maintainer_email 'ops@neon-lab.com'
license          'All rights reserved'
description      'Installs/Configures celebdating'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends 'python', "= 1.4.6"
depends 'apt'
depends 'git'
depends 'aws'

supports 'ubuntu'
