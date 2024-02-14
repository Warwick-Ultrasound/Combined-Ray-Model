function drawRay(ray, lineSpec)
    % draws a ray. If no 'stop' specified in ray yet, defaults to 30mm long
    % in x direction, with a warning.

    if ~isfield(ray, 'stop')
        ray.stop = ray.start(1)+30E-3;
        ray.stop(2) = ray.eq(ray.stop);
        warning('No ray end point specified before drawRay called.');
    end
    hold on;
    plot([ray.start(1), ray.stop(1)]/1E-3, [ray.start(2), ray.stop(2)]/1E-3, lineSpec);
    hold off;
end
    
    