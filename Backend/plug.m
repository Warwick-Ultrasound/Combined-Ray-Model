function v = plug(r, R, v_ave, ~)
    v = zeros(size(r));
    for ii = 1:length(r)
        if r(ii) < R
            v(ii) = v_ave;
        elseif r(ii) == R
            v(ii) = 0;
        else
            v(ii) = 0/0;
        end
    end
end