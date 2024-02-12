function geom = genGeometry(g)
    % Takes a struct which contains all of the geometrical inputs of the
    % system and returns another struct which contains locations of the
    % boundaries for later use.
    %
    % Input should have fields:
    %   thick : wall thickness
    %   R: interior radius
    %   thetaT: transducer wedge angle
    %   hp: height of piezo centre above pipe
    %   Lp: length of piezo element
    %   sep: separation distance between piezo centres

    % y values for pipe boundaries
    geom.pipeExtTop = g.thick; % top, exterior
    geom.pipeIntTop = 0; % top, interior
    geom.pipeIntBot = -g.R; % bottom, interior
    geom.pipeExtBot = -g.R - g.thick; % bottom, exterior

    % coords for piezo centres
    geom.piezoLeftCentre = [0, g.hp];
    geom.piezoRightCentre = [g.sep, g.hp];

    % equations of lines through piezos
    geom.piezoLeft = @(x) tand(g.thetaT)*x + geom.piezoLeftCentre(2);
    geom.piezoRight = @(x) -tand(g.thetaT)*x + geom.piezoRightCentre(2) + tand(g.thetaT)*geom.piezoRightCentre(1);

    % bounds for piezos
    xp = g.Lp/2 * cosd(g.thetaT); % half-length of piezo projected onto x direction
    yp = g.Lp/2 * sind(g.thetaT); % half-length of piezo projected onto y direction
    geom.piezoLeftBounds.x = [geom.piezoLeftCentre(1)-xp, geom.piezoLeftCentre(1)+xp];
    geom.piezoLeftBounds.y = [geom.piezoLeftCentre(2)-yp, geom.piezoLeftCentre(2)+yp];
    geom.piezoRightBounds.x = [geom.piezoRightCentre(1)-xp, geom.piezoRightCentre(1)+xp];
    geom.piezoRightBounds.y = [geom.piezoRightCentre(2)+yp, geom.piezoRightCentre(2)-yp];

    % retain transducer wedge angle for later
    geom.thetaT = g.thetaT;

end