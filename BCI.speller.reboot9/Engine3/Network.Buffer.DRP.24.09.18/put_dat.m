function result = put_dat( bufferD, hdr )
% result = put_dat( bufferD  )

if bufferD.running 
    
    try
        hdr.buf = single( hdr.buf );
        buffer( 'put_dat', hdr, bufferD.host, bufferD.port )
        result = true;
    catch
        result = 0;
    end
    
else
   
    result = 0;
    
end