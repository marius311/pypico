module fpico

    interface
        function fpico_has_output_(key,nkey)
            character(len=*) :: key
            integer :: nkey
            logical :: fpico_has_output_
        end function
    end interface

end module

subroutine fpico_load(file)
    character(len=*) :: file
    print *, "Loading PICO..."
    call fpico_load_(file,len(file))
end subroutine

subroutine fpico_set_param(name,value)
    character(len=*) :: name
    real(8) :: value
    call fpico_set_param_(name,len(name),value)
end subroutine

subroutine fpico_request_output(name)
    character(len=*) :: name
    call fpico_request_output_(name,len(name))
end subroutine


subroutine fpico_compute_result(success)
    use fpico
    logical :: success_
    logical, optional :: success
    call fpico_compute_result_(success_)
    if (present(success)) success=success_
end subroutine

subroutine fpico_get_output_len(key, nresult)
    character(len=*) :: key
    integer(4) :: nresult
    call fpico_get_output_len_(key, len(key), nresult)
end subroutine

subroutine fpico_read_output(key, result, istart, iend)
    character(len=*) :: key
    real(8), dimension(istart:iend) :: result
    integer(4) :: istart, iend
    call fpico_read_output_(key, len(key), result, istart, iend)
end subroutine


subroutine fpico_has_output(key,has_output)
    use fpico
    character(len=*) :: key
    logical, intent(out) :: has_output
    has_output = fpico_has_output_(key,len(key))
end subroutine


