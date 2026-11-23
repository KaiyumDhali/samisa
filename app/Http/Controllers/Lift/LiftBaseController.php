<?php

namespace App\Http\Controllers\Lift;

use App\Http\Controllers\Controller;
use App\Models\FinanceAccount;
use Illuminate\Support\Facades\Auth;
use RuntimeException;

abstract class LiftBaseController extends Controller
{
    protected function guardPermissions(array $readOnlyMethods): void
    {
        $this->middleware('permission:read lift service|write lift service', ['only' => $readOnlyMethods]);
        $this->middleware('permission:write lift service', ['except' => $readOnlyMethods]);
    }

    protected function customers()
    {
        return FinanceAccount::where('account_status', 1)
            ->where('account_group_code', (string) $GLOBALS['CustomerGroupCode'])
            ->orderBy('account_name')
            ->pluck('account_name', 'id');
    }

    protected function receiveAccounts()
    {
        return FinanceAccount::where('account_status', 1)
            ->whereIn('account_group_code', ['100020002', '100020003', '100020004'])
            ->orderBy('account_name')
            ->pluck('account_name', 'id');
    }

    protected function user(): string
    {
        return Auth::user()->name ?? 'System';
    }

    /**
     * Executes a service operation and redirects back with an error message
     * if a business or unexpected error occurs.
     */
    protected function run(callable $fn, string $okMessage, ?callable $redirect = null)
    {
        try {
            $result = $fn();
        } catch (RuntimeException $e) {
            return back()
                ->withErrors(['error' => $e->getMessage()])
                ->withInput();
        } catch (\Throwable $e) {
            report($e);

            return back()
                ->withErrors([
                    'error' => 'Something went wrong. The entry could not be saved. (' . $e->getMessage() . ')'
                ])
                ->withInput();
        }

        $resp = $redirect ? $redirect($result) : back();

        return $resp->with([
            'message' => $okMessage,
            'alert-type' => 'success'
        ]);
    }
}
