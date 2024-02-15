function sep = transducerPositionCalc(g, mat, pathKey)
    % Calculates the transducer separation required to receive a particular
    % path specified by the pathKey. Inputs are:
    % g: the geometry input struct (with no transducer separation)
    % mat: the materials struct
    % pathKey: 4 characters specifying path to calculate for
    %
    % The output is the centre-to-centre transducer separation in metres,
    % or NaN if path is not possible for the system input.
    
    xT = (g.hp-g.thick)*tand(g.thetaT); % x dist in transducer

    % angle in liquid
    theta_l = asind( mat.fluid.clong/mat.transducer.clong * sind(g.thetaT) );
    xl = 2*g.R*tand(theta_l); % distance in single water transit, zero flow

    xw = 0; % will hold total wall transit distance in x
    for ii = 1:length(pathKey)
        switch pathKey(ii)
            case 'L'
                theta_p = asind(mat.pipe.clong/mat.transducer.clong * sind(g.thetaT));
                xw = xw + g.thick*tand(theta_p);
            case 'S'
                theta_p = asind(mat.pipe.cshear/mat.transducer.clong * sind(g.thetaT));
                xw = xw + g.thick*tand(theta_p);
        end
    end

    sep = 2*xT + 2*xl + xw;

end