#-----------------------------------------------------------------------------
# Configuration file for jupyter nbconvert
#-----------------------------------------------------------------------------
import os
c = get_config()

# Set default PDF conversion command
# NOTE: Settings for HTML conversion are in jupyter_nbconvert_config.json
# See: https://nbconvert.readthedocs.io/en/latest/config_options.html
c.PDFExporter.verbose = True
c.PDFExporter.latex_count = 1
c.PDFExporter.latex_command = [os.path.expanduser('~/mambaforge/bin/tectonic'), '{filename}']  # noqa: E501
