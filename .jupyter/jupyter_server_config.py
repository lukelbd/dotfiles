# Enable code formatter to prevent popup message
# See: https://github.com/ryantam626/jupyterlab_code_formatter/issues/193#issuecomment-808169451
c.ServerApp.jpserver_extensions = {
    'jupyterlab': True,
    'jupyterlab_code_formatter': True,
}
