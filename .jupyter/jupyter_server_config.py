# Enable code formatter to prevent popup message.
# See: https://github.com/ryantam626/jupyterlab_code_formatter/issues/193#issuecomment-808169451
# However this did not actually work... instead had to downgrade
# to older version with 'pip install jupyterlab-code-formatter==1.5.3'.
# See: https://github.com/ryantam626/jupyterlab_code_formatter/issues/193#issuecomment-1488742233
c.ServerApp.jpserver_extensions = {
    'jupyterlab': True,
    'jupyterlab_code_formatter': True,
}
