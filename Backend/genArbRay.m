function ray = genArbRay(startCoords, theta, type, material, g, nextBound)
    % Used internally to generate a ray starting at any location, with a
    % given angle to the vertical (like refraction or reflection angle).
    % type is the wave type ('L' or 'S'), and material is the material
    % struct for the propagation medium, g is the geometry struct.
    % Automatically terminates the ray at the next interface. nextBound is
    % the field name of g that the ray will intersect with next as a
    % string.

    % equation of line
    m = -1/tand(theta);
    c = startCoords(2) + startCoords(1)/tand(theta);

    % insert into struct
    ray.eq = @(x) m*x + c;
    ray.material = material;
    ray.type = type;
    ray.start = startCoords;

    % calculate next intersection point. Ray always travelling to right.
    switch nextBound
        case {'pipeExtTop', 'pipeIntTop', 'pipeIntBot', 'pipeExtBot'}
            y = g.(nextBound); % y-value of boundary
            x = (y-c)/m;

        case 'piezoRight'

            % coeffs of right piezo line
            m2 = g.piezoRight(2)-g.piezoRight(1);
            c2 = g.piezoRight(0);

            % solution to sim. eqns.
            x = (c2-c)/(m-m2);
            y = g.piezoRight(x);

            % ensure that this is within piezo bounds
            xOutBounds = x<g.piezoRightBounds.x(1) || x>g.piezoRightBounds.x(2);
            yOutBounds = y>g.piezoRightBounds.y(1) || y<g.piezoRightBounds.y(2);

            if xOutBounds || yOutBounds
                x = nan;
                y = nan;
            end

    end
    ray.stop = [x,y];

end