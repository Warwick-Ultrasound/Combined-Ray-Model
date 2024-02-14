function ray = calcFluidRay(startCoords, theta0, flow, g, mat, varargin)
    % input arguments:
    %
    % startCoords: starting position of ray where it enters fluid
    % theta0: angle of ray when water is at rest
    % flow: struct of flow with fields:
    %   v_ave: pipe average flow velocity
    %   profile: function handle for flow profile
    %   N: nuber of points per transit
    %   n: order of tubulent profile. Set to anything if not using
    % g: geometry struct
    % mat: materials struct
    % N: Number of points required
    % n: order of turbulent profile, if using

    if nargin
        n = varargin{1};
    end
    
    % calculate y coords for the v-path
    if startCoords(2) == 0
        y = linspace(0, -2*g.R, flow.N);
        y_calc = linspace(g.R, -g.R, flow.N); % need to be between +/- R for calc
    elseif startCoords(2) == -2*g.R
        y = linspace(-2*g.R, 0, flow.N);
        y_calc = linspace(-g.R, g.R, flow.N); % need to be between +/- R for calc
    end
    dy = abs(y_calc(2)-y_calc(1));

    % now loop through them calculating x
    x = zeros(size(y_calc));
    x(1) = startCoords(1); % start at correct x location
    for ii = 2:length(y_calc)
        % local velocity
        v = flow.profile(y_calc(ii), g.R, flow.v_ave, n);
        theta_f = atand( tand(theta0) + v/(mat.fluid.clong*cosd(theta0)));
        x(ii) = x(ii-1) + dy*tand(theta_f);
    end

    % find total distance travelled
    ray.d = 0;
    for ii = 1:length(x)-1
        dx = x(ii+1)-x(ii);
        ray.d = ray.d + sqrt(dx^2 + dy^2);
    end

    % construct ray struct
    ray.start = startCoords;
    ray.stop = [x(end), y(end)];
    ray.coords = [x.',y.'];
    ray.material = mat.fluid;
    ray.type = 'L';
    ray.theta0 = theta0;
end