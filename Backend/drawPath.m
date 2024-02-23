function drawPath(path)
    % cycles through a path and plots all of the rays. Longitudinal are
    % plotted in blue and shear in red.

    rays = path.rays;
    for ii = 1:length(rays)
        if isempty(rays{ii})
            continue % skip that ray if there is nothing there
        end
        
        % determine lineSpec of ray
        switch rays{ii}.type
            case 'L'
                lineSpec = 'b-';
            case 'S'
                lineSpec = 'r-';
        end

        % draw ray
        if isfield(rays{ii}, 'eq') % straight ray
            hold on;
            drawRay(rays{ii}, lineSpec);
            hold off;

        elseif isfield(rays{ii}, 'coords')
            hold on;
            plot(rays{ii}.coords(:,1)/1E-3, rays{ii}.coords(:,2)/1E-3, lineSpec);
            hold off;

        end
    end

    % fix aspect ratio of plot
    xl = xlim;
    yl = ylim;
    pbaspect([diff(xl), diff(yl), 1]);
end