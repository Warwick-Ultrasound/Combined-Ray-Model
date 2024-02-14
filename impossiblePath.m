function path = impossiblePath(time, pathKey, Nrays, x0)
    % Sometimes, get a path taht is impossible because of critical angles.
    % This fucntion craetes a template to fill out the path in that case so
    % that it can be handled in functions which process the paths.
    path.time = time;
    path.burst = zeros(size(time));
    path.detected = 0;
    path.pathKey = pathKey;
    path.rays = cell(Nrays,1);
    for ii = 1:length(path.rays)
        path.rays{ii} = nan;
    end
    path.x0 = x0;
    path.pk_pk = 0;
end