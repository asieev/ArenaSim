export pdfnegbin_truncated

cdfnegbin(k; p, r) = one(k) - cdf(Beta(k+one(k),r),p)
pdfnegbin(k;p,r) = binomial( k+r - one(k), k) * (one(p) - p)^r * (p^k)
meannegbin(p,r) = (p*r) / (1 - p)


function pdfnegbin_truncated(k; p, r, maxwins)
    if k < maxwins
        pdfnegbin(k; p = p, r = r)
    elseif k == maxwins
        pdfnegbin(maxwins; p = p, r = r) + (1 - cdfnegbin(maxwins; p = p, r = r))
    else 
        zero(pdfnegbin(k; p = p, r = r))
    end
end

