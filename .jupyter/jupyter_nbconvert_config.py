# Configuration file for jupyter nbconvert
# See: https://stackoverflow.com/a/46251213/4970632
import os

c = get_config()
c.TemplateExporter.template_path = ['.', os.path.expanduser('~/.jupyter')]
c.LatexExporter.template_path = ['.', os.path.expanduser('~/.jupyter')]
