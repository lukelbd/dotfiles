% Add search paths
if ispc;
  base = getenv('USERPROFILE');
else;
  base = '~';
end
addpath([base '/matfuncs']);
% General settings
set(0, 'RecursionLimit', 50);
% Figure settings
set(0, 'DefaultFigureWindowStyle', 'normal');
set(0, 'DefaultFigureUnits', 'normalized');
set(0, 'DefaultFigurePosition', [0.5 0.25 0.5 0.5]);
set(0, 'DefaultFigureColor', 'w');
% Axis settings
set(0, 'DefaultAxesYGrid', 'on');
set(0, 'DefaultAxesXGrid', 'on');
set(0, 'DefaultAxesBox', 'on');
set(0, 'DefaultAxesXColor', [0.25 0.25 0.25]);
set(0, 'DefaultAxesYColor', [0.25 0.25 0.25]);
set(0, 'DefaultAxesXMinorTick', 'on');
set(0, 'DefaultAxesYMinorTick', 'on');
set(0, 'DefaultAxesXMinorGrid', 'off');
set(0, 'DefaultAxesYMinorTick', 'off');
set(0, 'DefaultAxesGridLineStyle', ':');
set(0, 'DefaultPatchEdgeColor', 'none');   % for contours; want no boundary by default
set(0, 'DefaultSurfaceEdgeColor', 'none'); % pcolor makes surfaces; want edgecolor none
set(0, 'DefaultAxesLayer', 'top');  % so grid lines, etc. are on top of e.g.  colormaps
set(0, 'DefaultAxesColorOrder', ... % set to R2014b+ color order
        [0      0.4470 0.7410;  ...
         0.8500 0.3250 0.0980;  ...
         0.9290 0.6940 0.1250;  ...
         0.4940 0.1840 0.5560;  ...
         0.4660 0.6740 0.1880;  ...
         0.3010 0.7450 0.9330;  ...
         0.6350 0.0780 0.1840]);
% Font settings
set(0, 'DefaultTextFontSize', 16);
set(0, 'DefaultAxesFontSize', 14);
set(0, 'DefaultUicontrolFontSize', 8);
set(0, 'DefaultAxesLineWidth', 1.2);
set(0, 'DefaultLineLineWidth', 1.2);
% Message
disp('Matlab configured.');
